import { React, useState } from 'react'
import { Navbar, Nav, NavDropdown, Container, Form, FormControl, Button } from 'react-bootstrap'
import { BrowserRouter as Router, Routes, Route, Link } from "react-router-dom";
import { ethers } from 'ethers'

import Home from './Home';
import Info from './Info';

export let ConnectedAddress;
export let IsWalletConncted;

function NavbarComp() {
  const [walletAddress, setWalletAddress] = useState("");

  async function requestAccount() {
    if (window.ethereum) {
        console.log('detected');
        try {
            const accounts = await window.ethereum.request({
                method: "eth_requestAccounts",
        });

        setWalletAddress(accounts[0]);
        ConnectedAddress = accounts[0]
        IsWalletConncted = Boolean(accounts[0]);
        connectWallet = accounts[0];
        console.log("account: " + accounts[0])

    } catch (error) {
        console.log("error account request");
    }

    } else {
        alert("Meta mask not deteched");
    }
  }

  async function connectWallet() {
    if(typeof window.ethereum !== "undefined") {
        await requestAccount();
    }
  }

  return (
    <Router>
    <div>
      <Navbar bg="light" expand="lg">
          <Container fluid>
            <Navbar.Brand as={Link} to={"/home"}>Fractionalize NFT</Navbar.Brand>
            <Navbar.Toggle aria-controls="navbarScroll" />
            <Navbar.Collapse id="navbarScroll">
              <Nav
                className="me-auto my-2 my-lg-0"
                style={{ maxHeight: '100px' }}
                navbarScroll
              >
                <Nav.Link as={Link} to={"/info"}>Info</Nav.Link>
                
              </Nav>
              <Form className="d-flex">

                <Button variant="outline-success"
                    onClick={connectWallet}>Connect Wallet</Button>
              </Form>
            </Navbar.Collapse>
          </Container>
      </Navbar>
    </div>
    <div>
      <Routes>
          <Route path="/home" element={<Home />} />
          <Route path="/info" element={<Info />} />
      </Routes>
    </div>
    </Router>
  )
}

export default NavbarComp;

