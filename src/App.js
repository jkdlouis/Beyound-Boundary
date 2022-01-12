import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { connect } from "./redux/blockchain/blockchainActions";
import { fetchData } from "./redux/data/dataActions";
import * as s from "./styles/globalStyles";
import styled from "styled-components";

const NFTCost = "0.25";

export const StyledButton = styled.button`
  padding: 8px;
`;

function App() {
  const blockchain = useSelector((state) => state.blockchain);
  const data = useSelector((state) => state.data);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const dispatch = useDispatch();

  console.log(24, data);

  const mint = () => {
    setStatus("Uploading to IPFS");
    // Need to call /api/verify-whitelist to get the whitelist signature
    // error handling needed
    // once the response status is 200, include the signature data in mint()
    blockchain.smartContract.methods
      .mint(blockchain.account)
      .send({
        from: blockchain.account,
        gasLimit: "285000",
        value: blockchain.web3.utils.toWei(NFTCost, "ether"),
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
    if (blockchain.account !== "" && blockchain.smartContract !== null) {
      dispatch(fetchData(blockchain.account));
    }
  }, [blockchain, dispatch]);

  return (
    <s.Screen>
      {blockchain.account === "" || blockchain.smartContract === null ? (
        <s.Container flex={1} ai={"center"} jc={"center"}>
          <s.TextTitle>Connect to Metamask</s.TextTitle>
          <s.SpacerSmall />
          <StyledButton
            onClick={(e) => {
              e.preventDefault();
              dispatch(connect());
            }}
          >
            CONNECT
          </StyledButton>
          <s.SpacerSmall />
          {blockchain.errorMsg !== "" ? (
            <s.TextDescription>{blockchain.errorMsg}</s.TextDescription>
          ) : null}
        </s.Container>
      ) : (
        <s.Container flex={1} ai={"center"} style={{ padding: 24 }}>
          <s.TextTitle style={{ textAlign: "center" }}>
            Welcome to Beyond Boundary Collection
          </s.TextTitle>
          {loading ? (
            <>
              <s.SpacerSmall />
              <s.TextDescription style={{ textAlign: "center" }}>
                loading...
              </s.TextDescription>
            </>
          ) : null}
          {status !== "" ? (
            <>
              <s.SpacerSmall />
              <s.TextDescription style={{ textAlign: "center" }}>
                {status}
              </s.TextDescription>
            </>
          ) : null}
          <s.SpacerLarge />
          <s.Container fd={"row"} jc={"center"}>
            <StyledButton
              onClick={(e) => {
                e.preventDefault();
                mint();
              }}
            >
              MINT
            </StyledButton>
          </s.Container>
          <s.SpacerLarge />
        </s.Container>
      )}
    </s.Screen>
  );
}

export default App;
