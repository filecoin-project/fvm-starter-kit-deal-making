# fvm-starter-kit-deal-making
Full dapp starter kit for automating Filecoin deal making

The whole flow for deal making (from file upload to making a deal on FVM) is described here: 

![shapes (6) copy](https://user-images.githubusercontent.com/782153/224225887-1a546129-62b5-41e8-b98d-eb52fe35fac8.png)

## (I) Data Prep

Files need to be converted and prepped for storage on FVM. 

Given a file A you want to upload, you need to gather four bits of information:

`(A1)` An https URL to the CAR file that represents A (`carLink`) (eg [this](https://bafybeif74tokne4wvxsrcsxh6dhrzv6ys7mtifhwzaen7jfjuvltean32a.ipfs.w3s.link/ipfs/bafybeif74tokne4wvxsrcsxh6dhrzv6ys7mtifhwzaen7jfjuvltean32a/baga6ea4seaqesm5ghdwocotmdavlrrzssfl33xho6xtrr5grwyi5gj3vtairaoq.car))

`(A2)` The size of A in bytes (`pieceSize`) 

`(A3)` The size of the CAR file that represents A in bytes (`carSize`) 

`(A4)` The piece CID of A (`commP`)


### Option A: Use FVM Tooling

Go to [data.fvm.dev](https://data.fvm.dev), upload A, and get these four fields out. 

Note: We hold your files for 30 days before the link to your car file expires. Make your smart contracts sometime soon after data prep so that your data can persist much longer through FVM!

### Option B: DIY Data Prep

1. Set up the [`generate-car`](https://github.com/tech-greedy/generate-car) go utility:

```bash
$ git clone https://github.com/tech-greedy/generate-car.git
$ cd generate-car
$ make build
```

Use the utility as follows:

```bash
$ mkdir out
$ ./generate-car --single -i /path/to/file/A.txt -o out -p /path/to/file/
```

You should get a json file that looks like this:
```json
{"Ipld":{"Name":"","Hash":"bafybeieawlmgtnb455ynra7kxyzipvhfxrms5yeuylr4w7dbpx7w4e6tqe","Size":0,"Link":[{"Name":"shapes.png","Hash":"bafybeigeisbcozxm7xyuf6vviijjg5fm2ptha2ciuyvjfdaedunhdfwsee","Size":1687130,"Link":null}]},"DataCid":"bafybeieawlmgtnb455ynra7kxyzipvhfxrms5yeuylr4w7dbpx7w4e6tqe","PieceCid":"baga6ea4seaqesm5ghdwocotmdavlrrzssfl33xho6xtrr5grwyi5gj3vtairaoq","PieceSize":2097152,"CidMap":{"":{"IsDir":true,"Cid":"bafybeieawlmgtnb455ynra7kxyzipvhfxrms5yeuylr4w7dbpx7w4e6tqe"},"shapes.png":{"IsDir":false,"Cid":"bafybeigeisbcozxm7xyuf6vviijjg5fm2ptha2ciuyvjfdaedunhdfwsee"}}}
```

Note that (A2) is `PieceSize`, (A3) is `Size`, (A4) is `PieceCid`. 

2. As a result of the above, you should also get a `.car` file. You can upload this file to [Web3.storage](https://web3.storage/), click on the CID column, and right click on the `Copy Link Location` once you get to the IPFS portal. You should get a link that looks something like this: https://bafybeif74tokne4wvxsrcsxh6dhrzv6ys7mtifhwzaen7jfjuvltean32a.ipfs.w3s.link/ipfs/bafybeif74tokne4wvxsrcsxh6dhrzv6ys7mtifhwzaen7jfjuvltean32a/baga6ea4seaqesm5ghdwocotmdavlrrzssfl33xho6xtrr5grwyi5gj3vtairaoq.car

This link is (A1) for your file.


## (II) Preparing the Deal Proposal Payload

Because of the way the client contract is set up, you need to prepare a deal proposal payload and call `makeDealProposal` with this payload. The payload consists of ([see more here](https://github.com/filecoin-project/fvm-starter-kit-deal-making/blob/main/frontend/src/components/Inputs.js)):

```javascript
  const extraParamsV1 = [
    carLink, // (A1)
    carSize, // (A3)
    false, // skipIpniAnnounce (whether or not the deal should be announced to IPNI indexers, set to false)
    false, // removeUnsealedCopy
  ];
  const DealRequestStruct = [
    cid.bytes, // (A4)
    pieceSize, // (A2)
    false, // verifiedDeal (whether the deal has datacap or not)
    commP, // label (how the deal is labelled, needs to be A4)
    520000, // startEpoch (when you want the storage to start)
    1555200, // endEpoch (when you want the storage to end)
    0, // storagePricePerEpoch (how much attoFIL per GiB per 30s you are offering for this deat, set to 0 for a free deal)
    0, // providerCollateral
    0, // clientCollateral
    1, // extraParamsVersion (set to 1)
    extraParamsV1,
  ];
```

### Option A: Use the dapp frontend

Take the four outputs of part (I) and put each into the four fields of the frontend in this repo. 

Once the deal handshake is completed (described more in part III), you should be able to see the deal ID for this transaction in Filfox on the frontend. Here is a previous example of a DealID submitted through the frontend: https://hyperspace.filfox.info/en/deal/1016.

### Option B: Other Scripts

While the above code snippet (and the logic for the dapp frontend) is implemented in javascript, you can implement this in many different langauges and formats. 

[Here is an (incomplete) example in Python](https://github.com/lotus-web3/dotStorage-deal-renewal/blob/main/scripts/renew.py). 

[Here is (a previously implemented one) in Go.](https://github.com/nonsense/datadaotool)

Note that these are both at various levels of completion. We encourage more scripts to be added here based on your development of these smart contracts here!

## (III) Interacting with the Client Contract (CC)

The CC is built to interact with Boost SPs and generate deals on behalf of a client, entirely on-chain. This differs from the deal bounty contract, for example, which relies on an offchain bonuty hunter in order to make deals.

The CC primarily interacts with the Boost SPs through an event known as `DealProposalCreate`, which looks like this:

```solidity
event DealProposalCreate(
    bytes32 indexed id,
    uint64 size,
    bool indexed verified,
    uint256 price
);
```

The eventual payload delivered to the Boost SPs is structured as follows (note this is simply the Solidity version of the javascript provided above):

```solidity
struct DealRequest {
    bytes piece_cid;
    uint64 piece_size;
    bool verified_deal;
    string label;
    int64 start_epoch;
    int64 end_epoch;
    uint256 storage_price_per_epoch;
    uint256 provider_collateral;
    uint256 client_collateral;
    uint64 extra_params_version;
    ExtraParamsV1 extra_params;
}

// Extra parameters associated with the deal request. These are off-protocol flags that
// the storage provider will need.
struct ExtraParamsV1 {
    string location_ref;
    uint64 car_size;
    bool skip_ipni_announce;
    bool remove_unsealed_copy;
}

```

The overall flow is a push-pull mechanism. The CC "pushes" a `DealProposalCreate` event onto the FVM event log, which is watched by Boost SPs. SPs look for `DealProposalCreate` events that interest them (they can filter by price, verified state and size). They then ask the CC to provide them the `DealProposal` payload. Data transfer can begin. SPs can also publish the deal by submitting a PSD message on-chain with the fields in the DealProposal payload.

See the diagram of this information here:

![shapes (6) copy](https://user-images.githubusercontent.com/782153/224235188-f1b2ecfc-c88b-4efb-9896-b90ec5c3152f.png)

The "front-end" of the CC interacts with the client, and takes in a deal proposal payload (eg Part II). The "back-end" of the CC interacts with the Boost SP in order to generate the deal, as well as in order to authenticate the deal. 

Note that we have a few active threads and FRCs where the client contract is being discussed: 
 - [Our latest FRC draft, WIP](https://www.notion.so/WIP-Deal-Client-Contract-FRC-458e625f13b14c70bfdfe7ed64007b6c)
 - [FIP discussion 604](https://github.com/filecoin-project/FIPs/discussions/604)
 - [Boost discussion 1160](https://github.com/filecoin-project/boost/discussions/1160)
 
 

 

