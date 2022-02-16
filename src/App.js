import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Container, Row, Col, Button, Accordion } from "react-bootstrap";
import { connect } from "./redux/blockchain/blockchainActions";
import { fetchData } from "./redux/data/dataActions";
import "bootstrap/dist/css/bootstrap.min.css";

function App() {
  const blockchain = useSelector((state) => state.blockchain);
  const data = useSelector((state) => state.data);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const dispatch = useDispatch();

  const mint = () => {
    setStatus("Uploading to IPFS");
    // Need to call /api/verify-whitelist to get the whitelist signature
    // post body: { body: { address: blockchain.account } }
    // Set loader
    // error handling needed
    // once the response status is 200, include the signature data in mint()
    // const listingPrice = "0.01";
    const listingPrice = blockchain.smartContract.methods.listingPrice().call();
    blockchain.smartContract.methods
      .mint(blockchain.account)
      .send({
        from: blockchain.account,
        gasLimit: "285000",
        value: blockchain.web3.utils.toWei(listingPrice, "ether"),
      })
      .once("error", (err) => {
        console.log(err);
        setLoading(false);
        setStatus("Error");
      })
      .then((receipt) => {
        console.log(receipt);
        setLoading(false);
        dispatch(fetchData(blockchain.account));
        setStatus("Successfully minting your NFT");
      });
  };

  useEffect(() => {
    if (blockchain.account) {
      dispatch(fetchData(blockchain.account));
    }
  }, [blockchain, dispatch]);

  return (
    <Container>
      <Row className="justify-content-between">
        <Col md={3}>
          <img src="https://via.placeholder.com/150" alt="logo"></img>
        </Col>
        <Col md={3}>
          <p>Wallet address: {blockchain.account}</p>
        </Col>
      </Row>
      {!blockchain.account && (
        <Row className="text-center">
          <Col>
            <h1>Connect to Metamask</h1>
            <Button
              onClick={(e) => {
                e.preventDefault();
                dispatch(connect());
              }}
            >
              Connect
            </Button>
            {blockchain.errorMsg && <p>{blockchain.errorMsg}</p>}
          </Col>
        </Row>
      )}
      {blockchain.account && (
        <Row className="text-center pt-5 pb-5">
          <Col>
            <h1>Welcome to Beyond Boundary Collection</h1>
            {loading && <p>loading...</p>}
            {status && <p>{status}</p>}
            <Button
              onClick={(e) => {
                e.preventDefault();
                mint();
              }}
            >
              Mint
            </Button>
          </Col>
        </Row>
      )}
      <Row className="pt-5 pb-5">
        <Col>
          <h2 className="text-center">Frequently Asked Questions</h2>
          <Accordion defaultActiveKey="0">
            <Accordion.Item eventKey="0">
              <Accordion.Header>Accordion Item #1</Accordion.Header>
              <Accordion.Body>
                Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
                eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
                enim ad minim veniam, quis nostrud exercitation ullamco laboris
                nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor
                in reprehenderit in voluptate velit esse cillum dolore eu fugiat
                nulla pariatur. Excepteur sint occaecat cupidatat non proident,
                sunt in culpa qui officia deserunt mollit anim id est laborum.
              </Accordion.Body>
            </Accordion.Item>
            <Accordion.Item eventKey="1">
              <Accordion.Header>Accordion Item #2</Accordion.Header>
              <Accordion.Body>
                Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
                eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
                enim ad minim veniam, quis nostrud exercitation ullamco laboris
                nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor
                in reprehenderit in voluptate velit esse cillum dolore eu fugiat
                nulla pariatur. Excepteur sint occaecat cupidatat non proident,
                sunt in culpa qui officia deserunt mollit anim id est laborum.
              </Accordion.Body>
            </Accordion.Item>
          </Accordion>
        </Col>
      </Row>
      <Row>{/* parallax section */}</Row>
      <Row>{/* footer section */}</Row>
    </Container>
  );
}

export default App;
