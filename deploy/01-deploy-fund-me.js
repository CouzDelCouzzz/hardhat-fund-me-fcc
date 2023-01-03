// import
// main function

// function deployFunc(hre) {
//     console.log("Hi!")
// }

// module.exports.default = deployFunc // Set the deployFunc as the default function

// hre = Hardhat Runtime Environment
// create an anonymous function
// module.exports = async (hre) => {
//     const { getNamedAccounts, deployments } = hre
//     // hre.getNamedAccounts
//     // hre.deployments
// }

const { networkConfig, developmentChain } = require("../helper-hardhat-config")
const { network } = require("hardhat")
const { verify } = require("../utils/verify.js")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    // if chainId is X use address Y -> modularise our code
    // const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    let ethUsdPriceFeedAddress
    if (developmentChain.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator") // name of the contract we deployed with the mock
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    // If contract doesn't exist, we deploy a minimal version of for our local node

    // What happends if we change the network ?
    // When going for localhost or hardhat network, we want to use a mock
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // priceFeedAddress
        log: true, // To print the transaction and the address
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (
        !developmentChain.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        // VERIFY
        await verify(fundMe.address, args)
    }
    log("----------------------------------------------------------")
}

module.exports.tags = ["all", "fundme"]
