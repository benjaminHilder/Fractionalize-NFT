import React from 'react';
import { Box, Button, Flex, Image, Link, Spacer, Text} from '@chakra-ui/react';


const NavBar = ({ accounts, setAccounts }) => {
    const isConnected = Boolean(accounts[0]);

    async function connectAccount() {
        if (window.ethereum) {
            const accounts = await window.ethereum.request({
                method: "eth_requestAccounts",
            });
            setAccounts(accounts);
        }
    }

return (
    <Flex justify="center" align="center" padding="30px">
    <Text textAlign={"left "}>Rinkeby TestNet</Text>
    {/* Connect */}
    {isConnected ? (
        <Box margin="0 15px">Connected</Box>
    ) : (

        <Button 
            backgroundColor="#2E4A84"
            borderRadius="5px"
            boxShadow="0px 2px 2px 1px #0F0F0F"
            color="white"
            cursor="pointer"
            fontFamily="inherit"
            padding="15px"
            margin="0 15px"
            onClick={connectAccount}
            >
                Connect Wallet
        </Button>

        
    )}

    <Text textAlign={"left"}>NFT Contract Address: 0x5f45E99F6F83630b34c815C585742eac229B2285</Text>

    <Flex justify="right" align="right" paddingLeft="30px">
    <Text>Coming soon: Auction Withdraw</Text>
    </Flex>
    </Flex>


)
}

export default NavBar;