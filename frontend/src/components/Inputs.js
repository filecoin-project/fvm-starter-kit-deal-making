import React, { useState, useEffect } from "react";
import contract from "../contracts/DealClient.json";
import "react-tooltip/dist/react-tooltip.css";
import { Tooltip } from "react-tooltip";
import { ethers } from "ethers";
import { AiOutlineQuestionCircle, AiOutlineLoading } from "react-icons/ai";
import { Spinner } from 'react-bootstrap';
const CID = require("cids");

 // Replace this address with the address of own instance of the deal client contract
const contractAddress = "0x9b2A284d382860F62F41258A9d1cCEfF56474f37";
const contractABI = contract.abi;
let dealClient;
let cid;

function Inputs() {
  // Initialize with some dummy working default values
  const [commP, setCommP] = useState(
    "baga6ea4seaqkp2pjlh6avlvee6ib2maanav5sc35l5glf3zm6rd6hmfgcx5xeji"
  );
  const [carLink, setCarLink] = useState(
    "https://data-depot.lighthouse.storage/api/download/download_car?fileId=862fb115-d24a-4ff1-a1c8-eadbbbfd19cf.car"
  );
  const [errorMessageSubmit, setErrorMessageSubmit] = useState("");
  const [pieceSize, setPieceSize] = useState("32768");
  const [carSize, setCarSize] = useState("18445");
  const [txSubmitted, setTxSubmitted] = useState("");
  const [dealID, setDealID] = useState("");
  const [proposingDeal, setProposingDeal] = useState(false);
  const [network, setNetwork] = useState("");

  const handleChangeCommP = (event) => {
    setCommP(event.target.value);
  };

  const handleChangeCarLink = (event) => {
    // validate input data here
    setCarLink(event.target.value);
  };

  const handleChangePieceSize = (event) => {
    setPieceSize(event.target.value);
  };

  const handleChangeCarSize = (event) => {
    setCarSize(event.target.value);
  };

  /*
  const handleChangeStartEpoch = (event) => {
    setStartEpoch(event.target.value);
  }

  const handleChangeEndEpoch = (event) => {
    setEndEpoch(event.target.value);
  }
  */

  const handleSubmit = async (event) => {
    // This will be handling deal proposal submission sometime in the future.
    event.preventDefault();
    // do something with the carLink value, like send it to a backend API
    console.log(commP);
    console.log(carLink);
    console.log(pieceSize);
    console.log(carSize);

    try {
      setErrorMessageSubmit(
        ""
      );
      cid = new CID(commP);
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.BrowserProvider(ethereum);
        const signer = await provider.getSigner();
        dealClient = new ethers.Contract(
          contractAddress,
          contractABI,
          signer
        );
        const extraParamsV1 = [
          carLink,
          carSize,
          false, // taskArgs.skipIpniAnnounce,
          false, // taskArgs.removeUnsealedCopy
        ];
        const DealRequestStruct = [
          cid.bytes, //cidHex
          pieceSize, //taskArgs.pieceSize,
          false, //taskArgs.verifiedDeal,
          commP, //taskArgs.label,
          520000, // startEpoch
          1555200, // endEpoch
          0, // taskArgs.storagePricePerEpoch,
          0, // taskArgs.providerCollateral,
          0, // taskArgs.clientCollateral,
          1, //taskArgs.extraParamsVersion,
          extraParamsV1,
        ];
        // console.log(await provider.getBalance("0x42c930a33280a7218bc924732d67dd84d6247af4"));
        console.log(dealClient.interface);
        const transaction = await dealClient.makeDealProposal(
          DealRequestStruct
        );
        console.log("Proposing deal...");
        setProposingDeal(true);
        const receipt = await transaction.wait();
        console.log(receipt);
        setProposingDeal(false);
        setTxSubmitted("Transaction submitted! " + receipt.hash);

        dealClient.on("DealProposalCreate", (id, size, verified, price)=>{
          console.log(id, size, verified, price);
        })

        console.log("Deal proposed! CID: " + cid);
      } else {
        console.log("Ethereum object doesn't exist!");
      }
    } catch (error) {
      console.log(error);
      setErrorMessageSubmit(
        "Something went wrong. " + error.name + " " + error.message
      );
      return;
    }
  };

  const checkWalletIsConnected = async () => {
    const { ethereum } = window;
    if (!ethereum) {
      console.log("Make sure you have metamask!");
      return;
    } else {
      console.log("We have the ethereum object", ethereum);
    }
    const provider = new ethers.BrowserProvider(ethereum);
    const network = await provider.getNetwork();
    setNetwork(network.chainId);
    console.log(network.chainId);

    ethereum.request({ method: "eth_accounts" }).then((accounts) => {
      if (accounts.length !== 0) {
        const account = accounts[0];
        console.log("Found an account:", account);
      } else {
        console.log("No account found");
      }
    });
  };

  const connectWalletHandler = () => {
    const { ethereum } = window;
    if (!ethereum) {
      alert("Get MetaMask!");
      return;
    }
    ethereum
      .request({ method: "eth_requestAccounts" })
      .then((accounts) => {
        console.log("Connected", accounts[0]);
      })
      .catch((err) => console.log(err));
  };

  const connectWalletButton = () => {
    return (
      <div style={{ display: "flex" }}> <div class="child-1-cw"> 
      <button
        onClick={connectWalletHandler}
        className="cta-button connect-wallet-button"
      >
        Connect Wallet
      </button>
      { window && <div style={{ color: "green" }}> Connected </div>}
      { network && <div style={{ color: "green" }}> Network: Hyperspace </div>}
      </div></div>
    );
  };

  const dealIDButton = () => {
    return (
      <button
        onClick={dealIDHandler}
      >
        Get deal ID
      </button>
    );
  };

  const dealIDHandler = async () => {
    setDealID("Waiting for acceptance by SP...");
    cid = new CID(commP);
    var refresh = setInterval(async () => {
        console.log(cid.bytes);
        if (cid === undefined) {
          setDealID("Error: CID not found");
          clearInterval(refresh);
        }
        console.log("Checking for deal ID...");
        const dealID = await dealClient.pieceDeals(cid.bytes);
        console.log(dealID);
        if (dealID !== undefined && dealID !== "0") {
          // 
          setDealID("https://hyperspace.filfox.info/en/deal/" + dealID);
          clearInterval(refresh);
        }
      }, 5000
    );
  };

  useEffect(() => {
    checkWalletIsConnected();
  }, []);

  return (
    <div id="container"> 
      <div style={{ display: "flex" }}> <div class="child-1-cw"> 
        {connectWalletButton()}
      </div></div>

      <form class="child-1"  onSubmit={handleSubmit}>

        <div class='child-1-hg'>

        <label>
          Link to CAR file
        </label>


        <div>
          <div class="tooltip"
            data-tooltip-id="carfile-tooltip"
            data-tooltip-delay-hide={50}
            data-tooltip-html=" Find a URL to your car file by going to data.fvm.dev and uploading your file (site in development). <br /> You can also go to tech-greedy/generate-car and upload the resulting car file to web3.storage."
          >
            <AiOutlineQuestionCircle />
          </div>
          <Tooltip id="carfile-tooltip" />
        </div>


        </div>


          <input class="input-elem"
            type="text"
            value={carLink}
            onChange={handleChangeCarLink}
          />
        
        <br />
        <br />

        <div class='child-1-hg'>

        <label> commP </label>

            <div
              class="tooltip"
              data-tooltip-id="commp-tooltip"
              data-tooltip-delay-hide={50}
              data-tooltip-html="This is also known as the Piece CID. <br /> You can go to data.fvm.dev and get this by uploading your file (site in development). <br />This also can be accessed as the output of tech-greedy/generate-car."
            >
              <AiOutlineQuestionCircle />
            </div>
            <Tooltip id="commp-tooltip" />

        </div>

          <input class="input-elem"
            type="text"
            value={commP}
            onChange={handleChangeCommP}
          />


        <br />
        <br />

        <div class='child-1-hg'>

        <label>
          Piece Size:
        </label>

        <div
          class="tooltip"
          data-tooltip-id="piecesize-tooltip"
          data-tooltip-delay-hide={50}
          data-tooltip-html="This is the number of bytes of your Piece (you can read more about Filecoin Pieces in the spec). <br /> You can go to data.fvm.dev and get this by uploading your file (site in development).<br /> This also can be accessed as the output of tech-greedy/generate-car."
        >
          <AiOutlineQuestionCircle />
        </div>
        <Tooltip id="piecesize-tooltip" />


        </div>

          <input class="input-elem"
            type="text"
            value={pieceSize}
            onChange={handleChangePieceSize}
          />
        <br />
        <br />

        <div class='child-1-hg'>

        <label>
          Car Size:
        </label>

        <div
          class="tooltip"
          data-tooltip-id="carsize-tooltip"
          data-tooltip-delay-hide={50}
          data-tooltip-html="This is the size of the CAR file in bytes. <br /> You can go to data.fvm.dev and get this by uploading your file (site in development). <br /> This can be accessed as the output of tech-greedy/generate-car."
        >
          <AiOutlineQuestionCircle />
        </div>
        <Tooltip id="carsize-tooltip" />


        </div>

          <input class="input-elem" type="text" value={carSize} onChange={handleChangeCarSize} />
        <br />
        <br />
        <button
          type="submit"
          style={{ display: "block", width: "50%", margin: "auto" }}
        >
          Submit
        </button>
        <div style={{ color: "red" }}> {errorMessageSubmit} </div>
        { proposingDeal && <div style={{ color: "orange" }}> Loading: {<Spinner />} </div>}
        <div style={{ color: "green" }}> {txSubmitted} </div>
      </form>

      <br />
      <br />
      <div class="child-1-hg"> 
        <div style={{ display: "flex", width: "50%", margin: "auto" }}> 
          {dealIDButton()}
        </div>
      </div>
      {dealID && <div style={{ color: "green", margin:"auto" }}> Deal: {dealID}  </div>}

    </div>
  );
}

export default Inputs;
