// constants
import Web3 from "web3";
import SmartContract from "../../contracts/SmartContract.json";
// log
import { fetchData } from "../data/dataActions";

const connectRequest = () => {
  return {
    type: "CONNECTION_REQUEST",
  };
};

const connectSuccess = (payload) => {
  return {
    type: "CONNECTION_SUCCESS",
    payload: payload,
  };
};

const connectFailed = (payload) => {
  return {
    type: "CONNECTION_FAILED",
    payload: payload,
  };
};

const updateAccountRequest = (payload) => {
  return {
    type: "UPDATE_ACCOUNT",
    payload: payload,
  };
};

export const connect = () => {
  return async (dispatch) => {
    dispatch(connectRequest());
    const { ethereum } = window;
    const isMetaMaskInstalled = ethereum && ethereum.isMetaMask;
    if (isMetaMaskInstalled) {
      let web3 = new Web3(window.ethereum);
      try {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        // const networkId = await window.ethereum.request({
        //   method: "net_version",
        // });
        const NetworkData = await SmartContract.networks['1641785591947'];

        // will eventually check hard code network id here
        // if (networkId == 1641785591947)
        if (NetworkData) {
          // If we deploy our contract with remix
          // we need to include the contract ABI in contracts folder
          // we will get this ABI from ether scan
          // we will change the below ABI to point to that json file
          // we will grab the contract address and replace it below
          const SmartContractObj = new web3.eth.Contract(
            // replace with just SmartContract
            SmartContract.abi,
            // replace contract address here
            NetworkData.address
          );
          dispatch(
            connectSuccess({
              account: accounts[0],
              smartContract: SmartContractObj,
              web3: web3,
            })
          );
          // Add listeners start
          window.ethereum.on("accountsChanged", (accounts) => {
            dispatch(updateAccount(accounts[0]));
          });
          window.ethereum.on("chainChanged", () => {
            window.location.reload();
          });
          // Add listeners end
        } else {
          dispatch(connectFailed("Change network to Ethereum."));
        }
      } catch (err) {
        dispatch(connectFailed("Something went wrong."));
      }
    } else {
      dispatch(connectFailed("Install Metamask."));
    }
  };
};

export const updateAccount = (account) => {
  return async (dispatch) => {
    dispatch(updateAccountRequest({ account: account }));
    dispatch(fetchData(account));
  };
};
