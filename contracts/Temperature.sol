// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @dev Oracle of the temperature.
 */
contract Temperature is Ownable, Pausable {
    // Assumed maximum data provider
    uint256 private constant MAX_PROVIDER = 5;
    // Assumed maximum temperature(including 2 decimal places)
    uint256 private constant MAX_TEMPERATURE = 10000;
    // Assumed minimum pledge amount
    uint256 private constant PLEDGE_AMOUNT = 100 ether;
    // Assumed minimum pledge block number
    uint256 private constant MIN_PLEDGE_NUMBER = 259200;
    // Assumed pledge reward
    uint256 private constant PLEDGE_REWAWD = 100;
    // Assumed last block number
    uint256 public lastBlockNumber = 0;
    // Current temperature
    int256 private temperature;

    // Each round
    struct SubmittedTemperature {
        address provider;
        int256 temperature;
    }
    SubmittedTemperature[] private submittedTemperatures;

    // All provider
    struct Provider {
        uint256 initNumber;
        uint256 count;
    }
    mapping(address => Provider) public providers;
    address[] public allProviders;

    error TemperatureInvalid(int256 temperature);
    error Unauthorized();
    error AddressInvalid(address sender);

    event ChangeTemperature(address indexed sender, int256 temperature);
    event ChangeTemperatureByNode(
        address indexed sender,
        int256 temperature,
        int256 avgTemperature
    );
    event ApplyProvider(address provider);
    event RecalProvider(address provider);

    constructor() {}

    /**
     * @dev Provider once only.
     */
    modifier ProviderNotExisted() {
        require(!_exists(msg.sender), "Provider existed");
        _;
    }

    /**
     * @dev Provider existed.
     */
    modifier ProviderExisted() {
        require(_exists(msg.sender), "Provider not existed");
        _;
    }

    /**
     * @dev Submit once only.
     */
    modifier SubmitOnceOnly() {
        SubmittedTemperature[]
            memory _submittedTemperatures = submittedTemperatures;
        if (_submittedTemperatures.length > 0) {
            for (uint8 i = 0; i < _submittedTemperatures.length; i++) {
                require(
                    _submittedTemperatures[i].provider != msg.sender,
                    "Repeat submit"
                );
            }
        }
        _;
    }

    // =============================
    // Temperature
    // =============================
    /**
     * @dev Get the temperature.
     */
    function getTemperature() external view whenNotPaused returns (int256) {
        require(lastBlockNumber > 0, "Initializing...");
        return temperature;
    }

    /**
     * @dev Set the temperature.
     */
    function setTemperature(int256 _temperature) external onlyOwner {
        require(lastBlockNumber > 0, "Initializing...");
        if (SignedMath.abs(_temperature) > MAX_TEMPERATURE) {
            revert TemperatureInvalid(_temperature);
        }
        temperature = _temperature;
        emit ChangeTemperature(msg.sender, _temperature);
    }

    /**
     * @dev Set the temperature.
     */
    function setTemperatureByNode(int256 _temperature)
        external
        SubmitOnceOnly
        ProviderExisted
        whenNotPaused
        returns (bool)
    {
        // check
        if (SignedMath.abs(_temperature) > MAX_TEMPERATURE) {
            revert TemperatureInvalid(_temperature);
        }
        require(lastBlockNumber > 0, "Initializing...");
        // push data
        if (submittedTemperatures.length < MAX_PROVIDER) {
            submittedTemperatures.push(
                SubmittedTemperature({
                    provider: msg.sender,
                    temperature: _temperature
                })
            );
            Provider storage provider = providers[msg.sender];
            provider.count += 1;
            return true;
        }

        // average temperature
        int256 avgTemperature = _calcAvgTemperature();
        temperature = avgTemperature;
        // settle
        if (block.number - lastBlockNumber >= MIN_PLEDGE_NUMBER) {
            // TODO Reward platform token by service times
            // lastBlockNumber = block.number;
        }
        emit ChangeTemperatureByNode(msg.sender, _temperature, avgTemperature);
        delete submittedTemperatures;
        return true;
    }

    /**
     * @dev calc average temperature.
     */
    function _calcAvgTemperature() internal view returns (int256) {
        SubmittedTemperature[]
            memory _submittedTemperatures = submittedTemperatures;
        int256 totalTemperature = 0;
        for (uint8 i = 0; i < _submittedTemperatures.length; i++) {
            totalTemperature = SignedSafeMath.add(
                totalTemperature,
                _submittedTemperatures[i].temperature
            );
        }
        return
            SignedSafeMath.div(
                totalTemperature,
                int256(_submittedTemperatures.length)
            );
    }

    /**
     * @dev if necessary.
     */
    function withdraw() public onlyOwner {
        (bool c, ) = payable(owner()).call{value: address(this).balance}("");
        require(c, "Transfer failed");
    }

    // =============================
    // Provider
    // =============================
    /**
     * @dev apply for the provider.
     */
    function applyProvider() external payable ProviderNotExisted {
        require(msg.value >= PLEDGE_AMOUNT, "Insufficient funds");
        allProviders.push(msg.sender);
        providers[msg.sender] = Provider({initNumber: block.number, count: 0});
        if (lastBlockNumber == 0 && allProviders.length >= MAX_PROVIDER) {
            lastBlockNumber = block.number;
        }
        emit ApplyProvider(msg.sender);
    }

    /**
     * @dev recall the provider.
     */
    function recallProvider() external ProviderExisted {
        require(
            block.number - providers[msg.sender].initNumber >=
                MIN_PLEDGE_NUMBER,
            "Wait more block"
        );
        _removeProvider();
        (bool c, ) = payable(msg.sender).call{value: PLEDGE_AMOUNT}("");
        require(c, "Transfer failed");
        emit RecalProvider(msg.sender);
    }

    /**
     * @dev remove the provider.
     */
    function removeProvider() external onlyOwner {
        _removeProvider();
    }

    /**
     * @dev remove the provider.
     */
    function _removeProvider() internal {
        _removeByAddress(msg.sender);
        delete providers[msg.sender];
    }

    /**
     * @dev provider is existed.
     */
    function _exists(address _address) internal view returns (bool) {
        address[] memory _allProviders = allProviders;
        for (uint256 i = 0; i < _allProviders.length; i++) {
            if (_allProviders[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // =============================
    // Address utils
    // =============================
    function _findByAddress(address _address) internal view returns (uint256) {
        uint256 i = 0;
        address[] memory _allProviders = allProviders;
        while (_allProviders[i] != _address) {
            i++;
        }
        return i;
    }

    /**
     * @dev Remove by address.
     */
    function _removeByAddress(address _address) internal {
        uint256 i = _findByAddress(_address);
        _removeByIndex(i);
    }

    /**
     * @dev Remove by index.
     */
    function _removeByIndex(uint256 index) internal {
        require(index < allProviders.length, "Index invalid");
        allProviders[index] = allProviders[allProviders.length - 1];
        allProviders.pop();
    }
}
