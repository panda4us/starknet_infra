
                                        InStarkCentive

                            
In the light of the recent Starware announcement, the idea behind the project is to create a supplementary contract that will both stimulate the growth of the liquidity for the protocols and keep users commited to the protocol by providing them with the additional incentive. We will be using Pragma source of randomness, Pragma Data feed and the contract InSTARK with some amount of STARK tokens.

The Algorithm is the following:

1. User is providing liquidity for the protocol A.
2. Protocol submits data to the InSTARKcentive contract.
3. Within contract we estimate current value of the deposit based on the Data feed from the main CEXes and recording Contract_Address and Value into the dictionary.
4. We are generating random seed using the current Value and the previous Contract_Address (basically any hashing function will do).
5. Using the random seed from the previous step we are generating an Offer, namely we are offerring an extra N STRK tokens calculated as Value*(1+random1(0,1))/const, if user commits the deposit for D days = random2(0,360) (we should check that he amount N is less the number of the remaining unlocked tokens).
 6. Within protocol A user is getting a PopUp with proof of randomness (if needed) asking if she is willing to commit for D days in return for N extra tokens. If she confirms,  N  tokens are being "locked" with all relevant data being recorded.
7. When user decides to withdraw the liquidity, if the D days have expired, she is provided with the bonus, otherwise the notification that the bonus will be dismissed.
Expected positive impact:

distributing fair incentive to all STARKNET project that are willing to implement a small modification to their UI.
gamification of the staking process. 
we can potentially limit this functionality to one use for protocol-wallet pair, meaning that if user is unhappy about her bonus, she is free to go and try her luck with a different protocol. 
