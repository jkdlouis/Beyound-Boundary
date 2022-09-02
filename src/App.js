import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { connect } from "./redux/blockchain/blockchainActions";
import { fetchData } from "./redux/data/dataActions";
import Icon from "./componets/icon";

function App() {
  const blockchain = useSelector((state) => state.blockchain);
  // const data = useSelector((state) => state.data);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [listingPrice, setListingPrice] = useState("0");
  const [maxSupply, setMaxSupply] = useState("0");
  const dispatch = useDispatch();

  const mint = async () => {
    setStatus("Minting in progress");
    setLoading(true);
    // Need to call /api/verify-whitelist to get the whitelist signature
    // post body: { body: { address: blockchain.account } }
    // Set loader
    // error handling needed
    // once the response status is 200, include the signature data in mint()
    // const listingPrice = "0.01";
    blockchain.smartContract.methods
      .mint(blockchain.account)
      .send({
        from: blockchain.account,
        // Todo: remove gasLimit for prod
        gasLimit: "285000",
        value: listingPrice,
      })
      .once("error", (err) => {
        console.log(err);
        setLoading(false);
        setStatus(err.messsage);
      })
      .then((receipt) => {
        console.log(receipt);
        setLoading(false);
        dispatch(fetchData(blockchain.account));
        setStatus("Successfully minted your NFT");
      });
  };

  useEffect(() => {
    if (blockchain.account) {
      dispatch(fetchData(blockchain.account));
    }
  }, [blockchain, dispatch]);

  useEffect(() => {
    try {
      const listingPrice =
        blockchain.smartContract &&
        blockchain.smartContract.methods &&
        blockchain.smartContract.methods.listingPrice().call();

      listingPrice && setListingPrice(listingPrice);
    } catch (err) {
      setStatus(err);
    }
  }, [blockchain]);

  useEffect(() => {
    try {
      const maxSupply =
        blockchain.smartContract &&
        blockchain.smartContract.methods &&
        blockchain.smartContract.methods.maxSupply().call();

      maxSupply && setMaxSupply(maxSupply);
    } catch (err) {
      setStatus(err);
    }
  }, [blockchain]);

  return (
    <div className="px-8 py-16">
      <header>
        <div className="flex justify-center">
          <img src="https://via.placeholder.com/150" width="200" alt="logo" />
        </div>
        <nav className="flex justify-center grid grid-rows-1 mt-10 border-b-solid border-b-2 pb-6">
          <ul className="flex justify-between list-none">
            <li className="mr-24">
              <a href="/info">Info</a>
            </li>
            <li className="mr-24">
              <a href="/team">Team</a>
            </li>
            <li className="mr-24">
              <a href="/artist">Artist</a>
            </li>
            <li className="mr-24">
              <a href="/partners">Partners</a>
            </li>
            <li className="mr-4">
              <a href="#">
                <Icon type="twitter"></Icon>
              </a>
            </li>
            <li>
              <a href="#">
                <Icon type="instagram"></Icon>
              </a>
            </li>
          </ul>
        </nav>
      </header>
      <main className="grid grid-col-1 flex justify-center">
        <div className="flex flex-col justify-center items-center">
          <img
            src="https://via.placeholder.com/150"
            alt="bb"
            className="my-14 w-1/3"
          />
          <audio controls>
            <source src="horse.ogg" type="audio/ogg" />
            <source src="horse.mp3" type="audio/mpeg" />
          </audio>
        </div>
        <div className="mt-20 mb-16 flex justify-center">
          <div className="grid grid-cols-2 gap-10 w-3/5 flex justify-between">
            <div className="text-lg">
              <h2 className="font-bold italic text-5xl mb-5">WHO IS BB?</h2>
              <p className="mb-3">
                An ambitious cyber boy who is on his way to become the first
                meta musician. He traverses betwen dimentions and worlds. He can
                find a home in any place, but no one place in the world is truly
                his home. He is really searching for a tribe. He is here with a
                mission to connect us all.
              </p>
              <p>BB is here to make your world downside up.</p>
            </div>
            <div className="w-full border-solid border-2 border-black rounded-md p-6">
              <h2 className="font-bold text-5xl text-indigo-600">BB VINTAGE</h2>
              <h3 className="my-2">September 14th, 2022</h3>
              <img
                src="https://via.placeholder.com/150"
                className="w-full h-12"
                alt="barcode"
              />
              <ul className="list-none">
                <li className="mt-3 mb-2">
                  PRICE ---------------------------- {listingPrice} ETH
                </li>
                <li>SUPPLY -------------------------- 0/${maxSupply}</li>
              </ul>
              <div className="flex justify-center mt-6">
                {status && <p>{status}</p>}
                {!blockchain.account && (
                  <button
                    className="border-solid border-2 border-purple-800 p-4 rounded-lg flex items-center"
                    onClick={(e) => {
                      e.preventDefault();
                      dispatch(connect());
                    }}
                    disabled={loading}
                  >
                    <span className="mr-2">CONNECT WALLET</span>
                    <Icon type="wallet" />
                  </button>
                )}
                {blockchain.account && (
                  <button
                    className="border-solid border-2 border-purple-800 p-4 rounded-lg"
                    onClick={(e) => {
                      e.preventDefault();
                      mint();
                    }}
                    disabled={loading}
                  >
                    Mint
                  </button>
                )}
                {blockchain.errorMsg && <p>{blockchain.errorMsg}</p>}
              </div>
            </div>
          </div>
        </div>
      </main>
      <footer className="flex flex-col justify-center items-center">
        <img
          src="https://via.placeholder.com/150"
          alt="footer-background"
          className="w-full h-16 mb-12"
        />
        <a
          href="#"
          className="border-solid border-2 border-black p-4 rounded-lg flex justify-between items-center"
        >
          <span className="mr-2">JOIN DISCORD</span> <Icon type="discord" />
        </a>
      </footer>
    </div>
  );
}

export default App;
