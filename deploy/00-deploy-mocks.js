const { network } = require("hardhat")
const {
    developmentChain,
    DECIMALS,
    INITIAL_ANSWER,
} = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    if (developmentChain.includes(network.name)) {
        log("Local network detected! Deploying mocks...")
        await deploy("MockV3Aggregator", {
            contract: "MockV3Aggregator",
            from: deployer,
            log: true,
            args: [DECIMALS, INITIAL_ANSWER], // Check in Github or in artifacts/contracts/src....
        })
        log("Mocks deployed!")
        log("-------------------------------------")
    }
}

module.exports.tags = ["all", "mocks"] // When we will want to deploy, we will specify tags to decide which script to deploy
// e.g. yarn hardhat deploy --tags mocks
