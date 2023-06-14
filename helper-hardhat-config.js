const { ethers } = require("hardhat")

const networkConfig = {
    3141: {
        name: "",
        tokensToBeMinted: 12000,
    },
    314: {
        name: "FilecoinMainnet",
        tokensToBeMinted: 12000,
    },
}

module.exports = {
    networkConfig,
    // developmentChains,
}
