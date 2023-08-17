// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        //before brodcast is not real tx
        HelperConfig helperConfig = new HelperConfig(); //HelperConfig contract'ı oluşturuldu
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); //HelperConfig contract'ı üzerinden activeNetworkConfig() struct'ından activeNetwork adresi elde edildi
        //after broadcast is real tx                                    //Normalde struct dindürüldüğünde parantez içerisinde virgüllü şekilde elemanların ayrılması gerekir
        //Fakat burada struct'ın içerisinde sadece bir eleman olduğu için virgül kullanılmalı

        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
