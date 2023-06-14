const { ethers } = require("hardhat")

const networkConfig = {
    314159: {
        name: "Calibration",
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
