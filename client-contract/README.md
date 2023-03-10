In order to set up and deploy the client contract,

### 1. Install Foundry

[Full directions here](https://github.com/foundry-rs/foundry)

```
curl -L https://foundry.paradigm.xyz | bash
source /Users/$USER/.zshrc
foundryup
```

If you are on MacOS, you might need to install libusb: `brew install libusb`

### 2. Set up directory


Run `forge build` to make sure all necessary libraries are installed.

Run `forge test` to install any necessary testing libraries.

Then run 
```
npm install
make build
```
### 3. Compile to Hyperspace

```
forge create --rpc-url https://api.hyperspace.node.glif.io/rpc/v1 --private-key $PRIVATE_KEY src/DealClient.sol:DealClient
```

### 4. Example variants in terms of building blocks

* A simple data DAO can be implemented with a client that adds cids through a voting mechanism
* Perpetual storage contracts can by implemented with clients that funds deals with defi mechanisms and recycle cids from expiring deals into their authorization sets
* Trustless third party data funding can be implemented with 1) public ability to authorize cids for the client 2) a funding mechanism that associates payments with particular cids and 3) an authorization policy that only allows deals that are fully funded to pass authorization

Some more extension ideas discussed here: https://github.com/lotus-web3/client-contract/blob/main/README.md
