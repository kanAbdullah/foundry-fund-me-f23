// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 STARTING_BALANCE = 10e18;
    uint256 GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployfundMe = new DeployFundMe();
        fundMe = deployfundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        //      console.log("msg.sender: ", msg.sender);
        //      console.log("fundme.i_owner(): ", fundme.i_owner());
        //      assertEq(fundme.i_owner(), msg.sender);

        assertEq(fundMe.getOwner(), msg.sender); //The code that should be
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund(); //send 0 value
    }

    function testUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: 0.1e18}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 0.1e18);
    }

    function testAddsToFunderToArrayOfFunders() public {
        // this is testing if fund function pushes the address to the array of funders
        vm.prank(USER);
        fundMe.fund{value: 0.1e18}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        //thanks to this modifier we don't
        vm.prank(USER); //need to write vm.prank and
        fundMe.fund{value: 0.1e18}(); //call fund.me in every test
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); //expectRevert ignores this line because it a vm function
        vm.prank(USER); //this line required to act like a sender
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //ARRANGE
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gasUsed: ", gasUsed);

        //ASSERT
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new balance
            //but hoax does it for us
            hoax(address(i), 0.1e18);
            fundMe.fund{value: 0.1e18}();
        }
        //ACT
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, fundMe.getOwner().balance);
    }
}
