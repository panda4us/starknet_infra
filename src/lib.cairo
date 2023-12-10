use starknet::ContractAddress;

#[derive(Drop, Copy, Serde)]
enum DataType {
    SpotEntry: felt252,
    FutureEntry: (felt252, u64),
    GenericEntry: felt252,
}

#[derive(Serde, Drop, Copy)]
struct PragmaPricesResponse {
    price: u128,
    decimals: u32,
    last_updated_timestamp: u64,
    num_sources_aggregated: u32,
    expiration_timestamp: Option<u64>,
}

#[derive(Serde, Drop, Copy)]
struct UserLiquidity {
    primary_token:felt252,
    secondary_token:felt252,
    primary_amount:felt252,
    secondary_amount:felt252,
    timestamp:u64,
    protocol_address:felt252,
    initial_value_Usd:u128;
    reward: u128,
    expiration_timestamp: u64,
}



#[starknet::interface]
trait IPragmaABI<TContractState> {
    fn get_data_median(self: @TContractState, data_type: DataType) -> PragmaPricesResponse;
}

#[starknet::interface]
trait HackTemplateABI<TContractState> {
    fn get_asset_price(self: @TContractState, asset_id: felt252) -> u128;
}

#[starknet::interface]
trait IExampleRandomness<TContractState> {
    fn get_last_random(self: @TContractState) -> felt252;
    fn request_my_randomness(
        ref self: TContractState,
        seed: u64,
        callback_address: ContractAddress,
        callback_fee_limit: u128,
        publish_delay: u64,
        num_words: u64
    );
    fn receive_random_words(
        ref self: TContractState,
        requestor_address: ContractAddress,
        request_id: u64,
        random_words: Span<felt252>
    );
}


#[starknet::contract]
mod HackTemplate {
    use super::{ContractAddress, HackTemplateABI, IPragmaABIDispatcher, IPragmaABIDispatcherTrait, PragmaPricesResponse, DataType};
    use array::{ArrayTrait, SpanTrait};
    use traits::{Into, TryInto};
    use starknet::get_block_timestamp;
    use option::OptionTrait;

    const ETH_USD: felt252 = 19514442401534788;  
    


    #[storage]
    struct Storage {
        pragma_contract: ContractAddress,
        summary_stats: ContractAddress,
        liquidity_map: LegacyMap::<ContractAddress, UserLiquidity>
        protocol_whitelist: LegacyMap::<ContractAddress, felt252>//name and the interaction address

    }

    #[constructor]
    fn constructor(ref self: ContractState, pragma_address: ContractAddress, summary_stats_address : ContractAddress) 
    {
        self.pragma_contract.write(pragma_address);
        self.summary_stats.write(summary_stats_address);
    }

    #[external(v0)]
    impl HackTemplateABIImpl of HackTemplateABI<ContractState> {
        fn get_asset_price(self: @ContractState, asset_id: felt252) -> u128 {
            // Retrieve the oracle dispatcher
            let oracle_dispatcher = IPragmaABIDispatcher {
                contract_address: self.pragma_contract.read()
            };

            // Call the Oracle contract, for a spot entry
            let output: PragmaPricesResponse = oracle_dispatcher
                .get_data_median(DataType::SpotEntry(asset_id));

            return output.price;
        }
    }
}



mod ExampleRandomness {
    use super::{ContractAddress, IExampleRandomness};
    use starknet::info::{get_block_number, get_caller_address, get_contract_address};
    use pragma_lib::abi::{IRandomnessDispatcher, IRandomnessDispatcherTrait};
    use array::{ArrayTrait, SpanTrait};
    use openzeppelin::token::erc20::{ERC20, interface::{IERC20Dispatcher, IERC20DispatcherTrait}};
    use traits::{TryInto, Into};

    #[storage]
    struct Storage {
        randomness_contract_address: ContractAddress,
        min_block_number_storage: u64,
        last_random_storage: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, randomness_contract_address: ContractAddress) {
        self.randomness_contract_address.write(randomness_contract_address);
    }

    #[external(v0)]
    impl IExampleRandomnessImpl of IExampleRandomness<ContractState> {
        fn get_last_random(self: @ContractState) -> felt252 {
            let last_random = self.last_random_storage.read();
            return last_random;
        }

        fn request_my_randomness(
            ref self: ContractState,
            seed: u64,
            callback_address: ContractAddress,
            callback_fee_limit: u128,
            publish_delay: u64,
            num_words: u64
        ) {
            let randomness_contract_address = self.randomness_contract_address.read();


            let eth_dispatcher = IERC20Dispatcher {
                contract_address: 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 // ETH Contract Address
                    .try_into()
                    .unwrap()
            };
            eth_dispatcher.approve(randomness_contract_address, callback_fee_limit.into());

            // Request the randomness
            let randomness_dispatcher = IRandomnessDispatcher {
                contract_address: randomness_contract_address
            };
            let request_id = randomness_dispatcher
                .request_random(
                    seed, callback_address, callback_fee_limit, publish_delay, num_words
                );

            let current_block_number = get_block_number();
            self.min_block_number_storage.write(current_block_number + publish_delay);

            return ();
        }


        fn receive_random_words(
            ref self: ContractState,
            requestor_address: ContractAddress,
            request_id: u64,
            random_words: Span<felt252>
        ) {
            // Have to make sure that the caller is the Pragma Randomness Oracle contract
            let caller_address = get_caller_address();
            assert(
                caller_address == self.randomness_contract_address.read(),
                'caller not randomness contract'
            );
            // and that the current block is within publish_delay of the request block
            let current_block_number = get_block_number();
            let min_block_number = self.min_block_number_storage.read();
            assert(min_block_number <= current_block_number, 'block number issue');

            // and that the requestor_address is what we expect it to be (can be self
            // or another contract address), checking for self in this case
            //let contract_address = get_contract_address();
            //assert(requestor_address == contract_address, 'requestor is not self');

            // Optionally: Can also make sure that request_id is what you expect it to be,
            // and that random_words_len==num_words

            // Your code using randomness!
            let random_word = *random_words.at(0);

            self.last_random_storage.write(random_word);

            return ();
        }
    }
}

