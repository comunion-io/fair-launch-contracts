// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IWEFair.sol";
import "./Error.sol";
import "./WEFair.sol";

// import "hardhat/console.sol";

contract WEFairFactory is Ownable, AccessControl {
    using SafeMath for uint;

    event WEFairCreated(
        address _creator,
        address _wesale,
        address _presaleToken,
        address _investToken,
        address _teamWallet,
        uint256 _amount,
        Parameters parameters
    );

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant DEX_ROUTER_SETTER_ROLE =
        keccak256("DEX_ROUTER_SETTER_ROLE");
    bytes32 private constant DEX_ROUTER = keccak256("DEX_ROUTER");
    bytes32 private constant WEFAIRS = keccak256("WEFAIRS");
    address public feeTo;
    address public transferSigner;

    string private name = "WEFair";
    string private version = "1.0";

    constructor(address _feeTo, address _transferSigner) {
        feeTo = _feeTo;
        transferSigner = _transferSigner;

        _grantRole(ADMIN_ROLE, _msgSender());

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(DEX_ROUTER_SETTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(DEX_ROUTER, DEX_ROUTER_SETTER_ROLE);
    }

    // Create a presale
    function createFair(
        address _teamWallet,
        address _presaleToken,
        address _investToken,
        Parameters memory _parameters
    ) external payable returns (address wefair) {
        if (_presaleToken == address(0)) {
            revert InvalidToken("ZA");
        }

        if (!hasRole(DEX_ROUTER, _parameters.router)) {
            revert UnsupportedDexRouter();
        }
        IERC20 presaleToken = IERC20(_presaleToken);
        if (_investToken == address(0)) {
            _parameters.investTokenDecimals = 18;
        } else {
            IERC20Metadata investToken = IERC20Metadata(_investToken);
            _parameters.investTokenDecimals = investToken.decimals();
        }
        // investToken.
        uint256 needDepositAmount;
        {
            needDepositAmount = _parameters.totalSellAmount;
            needDepositAmount = _parameters
                .totalSellAmount
                .mul(_parameters.liquidityRate)
                .div(1000000)
                .add(needDepositAmount);
        }
        if (
            presaleToken.allowance(_msgSender(), address(this)) <
            needDepositAmount
        ) {
            revert InsufficientAllowedPresaleAmount();
        }

        wefair = address(
            new WEFair(
                name,
                version,
                _msgSender(),
                _teamWallet,
                _presaleToken,
                _investToken,
                needDepositAmount,
                _parameters
            )
        );

        if (
            !presaleToken.transferFrom(
                _msgSender(),
                address(this),
                needDepositAmount
            )
        ) {
            revert InsufficientPresaleBalance();
        }
        presaleToken.transfer(wefair, needDepositAmount);
        _grantRole(WEFAIRS, wefair);
        emit WEFairCreated(
            _msgSender(),
            wefair,
            _presaleToken,
            _investToken,
            _teamWallet,
            needDepositAmount,
            _parameters
        );
    }

    // Set up a fee collection wallet
    function setFeeTo(address _feeTo) external onlyRole(ADMIN_ROLE) {
        feeTo = _feeTo;
    }

    // Set up a pre-sale signed version
    function setVersion(string memory _version) external onlyOwner {
        version = _version;
    }

    // Set signer
    function setTransferSigner(
        address _transferSigner
    ) external onlyRole(ADMIN_ROLE) {
        transferSigner = _transferSigner;
    }

    // Override the revoked role's pre-permissions
    function _revokeRole(bytes32 role, address account) internal override {
        if (role == ADMIN_ROLE && account == owner()) {
            revert IllegalOperation();
        }
        AccessControl._revokeRole(role, account);
    }
}
