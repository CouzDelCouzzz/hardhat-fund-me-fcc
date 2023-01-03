//Get funds from users
// Withdraw funds
// Set a minimum funding value in USD -> we will need to use an Oracle

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/** @title A contract for crownd funding
 *  @author Quentin Diprima
 *  @notice This contract is to demo a sample funding contract
 *  @dev the implements s_priceFeed as our library
 */
contract FundMe {
    // Type declaration
    using PriceConverter for uint256; // To use the library

    // State variable
    uint256 public constant MINIMUM_USD = 50 * 1e18; // To have the 18 decimals

    // To keep who is sending money and how much
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // So that only the contract's owner can call this function
        // require(msg.sender == owner, "Sender is not owner!"); -> The solution just below is more gas efficient
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // represents "Do the rest of the code"
    }

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender; // Who ever deployed this contract
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    function fund() public payable {
        // We want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract ?

        // We accept only if the value sent is more than 1ETH
        // if the condition is not met, it will revert
        // Revert undo any action before, and send remaining gas back. The only gas used is for the code executed before the "require" statement
        // require(msg.value > 1e18, "Didn't send enough!"); // 1e18 = 1ETH
        // msg.value will be 18 decimals
        //require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough!");
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); // We don't need to pass the first parameter as it's implicitly msg.value
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        /* starting index; ending index; step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // Reset the array
        s_funders = new address[](0);
        // Actually withdraw the funds

        // There are 3 ways of sending ETh  -> https://solidity-by-example.org/sending-ether/
        // 1 - TRANSFER
        // msg.sender = address
        // paybale(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance); // if it fails, will return an error and revert the transaction

        // 2 - SEND
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // 3 - CALL  -> extremlly powerful
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;

        // mappings can't be in memory....

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    // What happens if someone sends this contract ETH without calling the fund function ?
    // received() -> this special function is called when someone is doing a transaction on our contract without calldata
    // fallback() -> this special function is called when someone is doing a transaction on our contract wwith some calldata but it doesn't match a function

    // ETH is sent to a contract
    //          is msg.data empty ?
    //              /   \
    //            yes   no
    //            /       \
    //        receive()?   fallback()
    //         /     \
    //        yes    no
    //        /         \
    //    receive()     fallback()
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
