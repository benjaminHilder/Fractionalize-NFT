import { React, Component, useState } from 'react'
import '../Main.css'
import { Container, Row, Col, Button, Alert, Breadcrumb, Card, Form } from "react-bootstrap"
import { Link, useMatch, useResolvedPath} from "react-router-dom";
import { ConnectedAddress } from './NavbarComp';

export let SelectedNft;

function Home() {
    const [walletData, setWalletData] = useState([])

    const getWalletData = () => {
        const options = {method: 'GET', headers: {Accept: 'application/json'}};
        
        fetch(`https://testnets-api.opensea.io/api/v1/assets?owner=${ConnectedAddress}&order_direction=desc&limit=20&include_orders=false`, 
        options
        )
          .then(response => response.json())
          .then(response => setWalletData(response.assets))
          .catch(err => console.error(err));

          console.log("Wallet data: " + walletData)
    }

    const renderNfts = (nft, index) => {
        return(
            <Button 
            key={index}
            onClick={() => SelectedNft = nft}>
                <CustomLink to="/">
                    <img src={nft.image_url} />
                </CustomLink>

                <p>{nft. name} #{nft.token_id}</p>
            </Button>
        )
    }
    return(
        <div className="main">
            <Container>
                <Form>
                    <Row>
                        <Col md> 
                            <h1>Fractionalize NFT</h1>
                            <Form.Group>
                            
                                <Button onClick={getWalletData}>Get NFTs</Button>
                                {walletData.map(renderNfts)}
                            </Form.Group>
                        </Col>
                    </Row>
                </Form>
            </Container>
        </div>
    )

    function CustomLink( { to, children, ...props }) {
        const resolvedPath = useResolvedPath(to)
        const isActive = useMatch({ path: resolvedPath.pathname, end: true })
        return (
            <li className={isActive ? "active" : ""}>
                <Link to={to} {...props}>{children}</Link>
            </li>
        )
    }
}

export default Home