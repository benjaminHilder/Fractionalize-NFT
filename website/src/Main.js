import { useState } from 'react';
import { ethers, BigNumber } from 'ethers';
import { Box, Button, Flex, Input, Text} from "@chakra-ui/react";
import  NFTGenerator from './json/NFTGenerator.json';
import  MainContract from './json/MainContract.json';

const NFTGeneratorAddress = "0x5f45E99F6F83630b34c815C585742eac229B2285";
const NFTFractionaliseAddress = "0x0A414b4252b0d61E5801e82d5AD63fFBf99eda82";

const CreateSampleNft = ({ accounts, setAccounts }) => {
    //const [mintAmount, setMintAmount ] = useState(1);
    const [mintId, setMintId] = useState();
    const [contractAddress, setContractAddress] = useState("0x5f45E99F6F83630b34c815C585742eac229B2285");
    const [nftId, setNftId] = useState();
    const [nftIdStill, setNFTIdStill] = useState();
    const [fractionIdStill, setFractionIdStill] = useState();
    const [tokenName, setTokenName] = useState()
    const [tokenTicker, setTokenTicker] = useState()
    const [supply, setSupply] = useState()
    const [royalty, setRoyalty] = useState()

    const [fractionId, setFractionId] = useState()
    const [withdrawContractAddress, setWithdrawContractAddress] = useState("0x5f45E99F6F83630b34c815C585742eac229B2285")
    const [withdrawId, setWithdrawId] = useState()
    const [withdrawFractionAddress, setWithdrawFractionAddress] = useState()
    const [fractionAddress, setFractionAddress] = useState()

    const isConnected = Boolean(accounts[0]);
    const handleChangeMintId = (event) => setMintId(event.target.value);
    const handleChangeContractAddress = (event) => setContractAddress(event.target.value);
    const handleChangeTokenName = (event) => setTokenName(event.target.value);
    const handleChangeTokenTicker = (event) => setTokenTicker(event.target.value);
    const handleChangeSupply = (event) => setSupply(event.target.value);
    const handleChangeRoyalty = (event) => setRoyalty(event.target.value);
    const handleChangeNftId = (event) => setNftId(event.target.value);

    const handleChangeFractionId = (event) => setFractionId(event.target.value);
    const handleChangeWithdrawContractAddress = (event) => setWithdrawContractAddress(event.target.value);
    const handleChangeWithdrawId = (event) => setWithdrawId(event.target.value);
    const handleChangeWithdrawFractionAddress = (event) => setWithdrawFractionAddress(event.target.value);

    async function handleMint() {
        if(window.ethereum) {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(
                NFTGeneratorAddress,
                NFTGenerator.abi,
                signer
            );
            try {
                const response = await contract.safeMint(accounts[0], BigNumber.from(mintId));
                setContractAddress(NFTGeneratorAddress);
                console.log('response: ', response);
            } catch (err) {
                console.log("error", err);
            }
        }
    }

    async function handleAutoMintNext() {
        if(window.ethereum) {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(
                NFTGeneratorAddress,
                NFTGenerator.abi,
                signer
            );
            try {
                const response = await contract.safeMintNextId();
                setContractAddress(NFTGeneratorAddress);
                setWithdrawContractAddress(NFTGeneratorAddress);
                


                console.log('response: ', response);
            } catch (err) {
                console.log("error", err);
            }

            try {
                const responseId = await contract.getSupply();
                setNftId(responseId);
                setNFTIdStill(responseId);
                setWithdrawId(responseId)

            } catch (err) {
                console.log("error", err)
            }
        }
    }

    async function handleApproveMainContract() {
        if(window.ethereum) {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(
                NFTGeneratorAddress,
                NFTGenerator.abi,
                signer
            );
            try {
                const response = await contract.approve(NFTFractionaliseAddress, nftId);
                console.log('response: ', response);
            } catch (err) {
                console.log("error", err);
            }
        }
    }

    async function handleDepositNFT() {
        if(window.ethereum) {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(
                NFTFractionaliseAddress,
                MainContract.abi,
                signer
            );
            try {
                const response = await contract.depositNft(NFTGeneratorAddress, nftId);

                console.log('response: ', response);
            } catch (err) {
                console.log("error", err);
            }
        }
    }

    async function handleFractionNft() {
        if(window.ethereum) {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(
                NFTFractionaliseAddress,
                MainContract.abi,
                signer
            );
            try {
                const response = await contract.createFraction(contractAddress,
                                                               BigNumber.from(nftId),
                                                               BigNumber.from(royalty),
                                                               BigNumber.from(supply),
                                                               tokenName.toString(),
                                                               tokenTicker.toString());
                console.log('response: ', response);
            } catch (err) {
                console.log("error", err);
            }

            try {
                const responseFractionID = await contract.getLastFractionId(accounts[0]) - 1;
                setFractionId(responseFractionID)
                setFractionIdStill(responseFractionID)
                console.log('response: ', responseFractionID);
            } catch (err) {
                console.log("error", err);
                console.log("address: ", accounts[0])
            }
        }
    }

    async function getFractionContractAddress() {
        if(window.ethereum) {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(
                NFTFractionaliseAddress,
                MainContract.abi,
                signer
            );
            try {
                const response = await contract.getFractionContractAddress(accounts[0], fractionId);
                setFractionAddress(response)
                setWithdrawFractionAddress(response)

                console.log('response: ', response);
            } catch (err) {
                //console.log("error", err);
                console.log("accounts[0]: " + accounts[0])
                console.log("fractionId: " + fractionId)
            }
        }
    }

    async function handleWithdraw() {
        if(window.ethereum) {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(
                NFTFractionaliseAddress,
                MainContract.abi,
                signer
            );
            try {
                //const fractionToken = await contract.searchForFractionToken(withdrawContractAddress, withdrawId);
                const response = await contract.withdrawNft(withdrawContractAddress, withdrawId, fractionAddress);
                console.log('response: ', response);
            } catch (err) {
                console.log("error " + err)
                console.log("withdrawContractAddress: " + withdrawContractAddress)
                console.log("withdrawId: " + withdrawId)
            }
        }
    }




    


    return (
        <Flex justify="center" align="center" height="50vh">
        {/*create sample nft */}

        <Box width="520px" height="59vh">
            <div>
            <Text fontSize="48px" textShadow="0 5px #0000000" >1.</Text>
            
            <Text fontSize="48px" textShadow="0 5px #0000000" >Sample NFT</Text>
            <Text
            fontSize="30px" height="0px" textShadow="0 5px #0000000" 
            >Mint a sample NFT to fractionalise
            </Text>

            </div>
            {isConnected ? (
                <div>
                    <Flex align="center" justify="center">

                <Button 
                          backgroundColor="#2E4A84"
                          borderRadius="5px"
                          boxShadow="0px 2px 2px 1px #0F0F0F"
                          color="white"
                          cursor="pointer"
                          fontFamily="inherit"
                          padding="15px"
                          marginTop="10px"
                          onClick={handleAutoMintNext}
                >Mint</Button>
                    
            
                     {/* Mint button*/}


            </Flex>
            <Text
            fontSize="30px"
            letterSpacing="-5.5%"
            fontFamily="inherit"

            >Your latest NFT ID:
            </Text>

            <Input      
                fontFamily="inherit"
                width="150px"
                height="40px"
                textAlign="center"
                paddingLeft="19px"
                marginTop="10px"
                padding="15px"
                contentEditable="false"
                
                value={nftIdStill}
                ></Input>

            <Text
            fontSize="30px"
            letterSpacing="-5.5%"
            fontFamily="inherit"

            >Your latest fraction ID:
            </Text>

            <Input      
                fontFamily="inherit"
                width="150px"
                height="40px"
                textAlign="center"
                paddingLeft="19px"
                marginTop="10px"
                padding="15px"
                contentEditable="false"
                
                value={fractionIdStill}
                ></Input>
                   
                </div>
            ) : (
                <Text></Text>
              
            )}
            </Box>

        {/*fractionalise Nft */}
        
        <Box width="620px" height="60vh">
            <div>
            <Text fontSize="48px" textShadow="0 5px #0000000" >2.</Text>
            <Text fontSize="48px" textShadow="0 5px #0000000" >Fraction NFT</Text>

            </div>
            {isConnected ? (
                <div>
                    {/* contract address*/}
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >Contract Address: </Text>
                    <Flex align="center" justify="center">
                   
                     <Input      
                        fontFamily="inherit"
                        width="1000px"
                        height="40px"
                        textAlign="center"
                        paddingLeft="19px"
                        marginTop="10px"
                        
                        value={contractAddress}
                        onChange={handleChangeContractAddress}
                        />


                    </Flex>
                    {/*Id*/}
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >NFT ID: </Text>
                    <Flex align="center" justify="center">
                    <Input
                        fontFamily="inherit"
                        width="100px"
                        height="40px"
                        marginTop="10px"
                        textAlign="center"
                        type="number"
                        value={nftId}
                        onChange={handleChangeNftId}
                        />
                    </Flex>

                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >New Token Name: </Text>
                    <Flex align="center" justify="center">
                    <Input
                        fontFamily="inherit"
                        width="350px"
                        height="40px"
                        textAlign="center"
                        marginTop="10px"
                        value={tokenName}
                        onChange={handleChangeTokenName}
                        />
                    </Flex>

                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >Token Ticker: </Text>
                    <Flex align="center" justify="center">
                    <Input
                        fontFamily="inherit"
                        width="100px"
                        height="40px"
                        marginTop="10px"
                        textAlign="center"
                        value={tokenTicker}
                        onChange={handleChangeTokenTicker}
                        />
                    </Flex>

                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >Supply: </Text>  
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >(add 18 zeros to your number) </Text>
                    <Flex align="center" justify="center">
                    <Input
                        fontFamily="inherit"
                        width="200px"
                        height="40px"
                        marginTop="10px"
                        type="number"
                        textAlign="center"
                        value={supply}
                        onChange={handleChangeSupply}
                        />
                    </Flex>

                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >Royalty: </Text>  
                    <Flex align="center" justify="center">
                    <Input
                        fontFamily="inherit"
                        width="200px"
                        height="40px"
                        marginTop="10px"
                        type="number"
                        textAlign="center"
                        value={royalty}
                        onChange={handleChangeRoyalty}
                        />
                    </Flex>
                    <Button 
                            backgroundColor="#2E4A84"
                              borderRadius="5px"
                              boxShadow="0px 2px 2px 1px #0F0F0F"
                              color="white"
                              cursor="pointer"
                              fontFamily="inherit"
                              padding="15px"
                              marginTop="10px"
                              onClick={handleApproveMainContract}
                              >Approve Contract
                    </Button>
                    <Button 
                            backgroundColor="#2E4A84"
                              borderRadius="5px"
                              boxShadow="0px 2px 2px 1px #0F0F0F"
                              color="white"
                              cursor="pointer"
                              fontFamily="inherit"
                              padding="15px"
                              marginTop="10px"
                              onClick={handleDepositNFT}
                              >Deposit NFT
                    </Button>
                    <Button 
                              backgroundColor="#2E4A84"
                              borderRadius="5px"
                              boxShadow="0px 2px 2px 1px #0F0F0F"
                              color="white"
                              cursor="pointer"
                              fontFamily="inherit"
                              padding="15px"
                              marginTop="10px"
                              onClick={handleFractionNft}
                    >Fractionalise NFT</Button>
                    
                </div>
            ) : (
                <Input
                fontFamily="inherit"
                fontSize = "30px"
                width="400px"
                height="55px"
                textAlign="center"
                paddingLeft="19px"
                marginTop="10px"
                padding="15px"
                contentEditable="false"
                value="Please connect your wallet"
                ></Input>
            )}
            </Box>

        {/*fraction nft erc 20 address*/}

        <Box width="520px" height="59vh">
            <div>
            <Text fontSize="48px" textShadow="0 5px #0000000" >3.</Text>
            <Text fontSize="48px" textShadow="0 5px #0000000" >Get Fraction Address</Text>

            </div>
            {isConnected ? (
                <div>
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >Fraction ID: </Text>  
                    <Flex align="center" justify="center">

                    <Input
                        fontFamily="inherit"
                        width="200px"
                        height="40px"
                        marginTop="10px"
                        type="number"
                        textAlign="center"
                        value={fractionId}
                        onChange={handleChangeFractionId}
                        />
                    </Flex>

                    <Flex align="center" justify="center">

                    <Button 
                              backgroundColor="#2E4A84"
                              borderRadius="5px"
                              boxShadow="0px 2px 2px 1px #0F0F0F"
                              color="white"
                              cursor="pointer"
                              fontFamily="inherit"
                              padding="15px"
                              marginTop="10px"
                             // onClick={handleMint}
                        onClick={() => {
                            getFractionContractAddress()
                            
                        }}

                    >Get address</Button>

                    </Flex>
                    <Flex align="center" justify="center">
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >
                    {fractionAddress} </Text>
                    
                    </Flex>
                    <Flex align="center" justify="center">
                    <Text fontSize="35px" height="0px" textShadow="0 5px #0000000" >Withdraw NFT </Text>
                    </Flex>
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >(Must own all fractions) </Text>
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >Contract Address: </Text>
                    <Flex align="center" justify="center">
                   
                     <Input      
                        fontFamily="inherit"
                        width="1000px"
                        height="40px"
                        textAlign="center"
                        paddingLeft="19px"
                        marginTop="10px"
                        
                        value={withdrawContractAddress}
                        onChange={handleChangeWithdrawContractAddress}
                        />
                        


                    </Flex>
                    <p>Fraction Address:</p>
                    <Input      
                        fontFamily="inherit"
                        width="520px"
                        height="40px"
                        textAlign="center"
                        paddingLeft="19px"
                        marginTop="10px"
                        
                        value={withdrawFractionAddress}
                        onChange={handleChangeWithdrawFractionAddress}
                        />

                    {/*Id*/}
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >NFT ID: </Text>
                    <Flex align="center" justify="center">
                    <Input
                        fontFamily="inherit"
                        width="100px"
                        height="40px"
                        marginTop="10px"
                        type="number"
                        textAlign="center"
                        value={withdrawId}
                        onChange={handleChangeWithdrawId}
                        />
                        </Flex>
                    <Flex align="center" justify="center">
                    <Button 
                              backgroundColor="#2E4A84"
                              borderRadius="5px"
                              boxShadow="0px 2px 2px 1px #0F0F0F"
                              color="white"
                              cursor="pointer"
                              fontFamily="inherit"
                              padding="15px"
                              marginTop="10px"
                             // onClick={handleMint}
                        onClick={() => {
                            handleWithdraw({gasLimit:30000})
                            //setFractionAddress({fractionAddress});
                        }}

                    >Withdraw</Button>
                        
                    </Flex>
                    <Text fontSize="35px" height="0px" textShadow="0 5px #0000000" >Withdraw Auction </Text>
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >(if you dont own all fractions) </Text>
                    <Text fontSize="15px" height="0px" textShadow="0 5px #0000000" >Coming soon </Text>
                </div>
            ) : (
                <Text></Text>
            )}

            </Box>
        </Flex>

    )
}

export default CreateSampleNft;