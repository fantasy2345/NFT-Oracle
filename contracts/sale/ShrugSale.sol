// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IShrugToken.sol";
import "../curves/Exponential.sol";

/**
 * @title Shrug Sale Contract
 */
contract ShrugSale is Exponential, ReentrancyGuard {

    /// @notice Event emitted only on construction. To be used by indexers
    event ShrugSaleDeployed();

    /// @notice Recipients update event
    event UpdatedRecipients(
        address[] recipients
    );

    /// @notice Token bought event
    event TokenBought(
        address buyer,
        uint256 firstTokenId,
        uint256 lastTokenId,
        uint256 value,
        string currency
    );

    /// @notice addresses of recipients who received the funds
    address[] public recipients;

    /// @notice ERC721 NFT
    IShrugToken public token;

    /// @notice USDT token contract
    IERC20 public USDTToken;

    /// @notice STMX token contract
    IERC20 public STMXToken;

    /**
     * @dev Constructor function
     * @param _token Token Instance
     */
    constructor(
        IShrugToken _token
    ) {
        token = _token;

        emit ShrugSaleDeployed();
    }

    /**
     * @dev Set recipients
     * @param _recipients array of recipients' address
     */
    function setRecipients(address[] memory _recipients) external onlyOwner {
        require(
            _recipients.length > 0,
            "ShrugSale: Empty array is provided"
        );
        require(
            _recipients.length <= 2,
            "ShrugSale: Count of recipients can't exceed 2"
        );
        
        for(uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "ShrugSale: Invalid recipient address");
        }

        recipients = _recipients;

        emit UpdatedRecipients(_recipients);
    }

    /**
     * @dev Buy Function in ETH
     * @param _count Count of tokens to buy
     */
    function buyInETH(uint256 _count) external payable nonReentrant {
        require(
            _count < 100,
            "ShrugSale: Count should be less than 100"
        );
        require(
            (token.totalSupply() + _count) <= token.maxSupply(),
            "ShrugSale: All tokens are minted"
        );

        uint256 price = getPrice(_count, 0);
        require(
            msg.value == price,
            "ShrugSale: Value is not same as the price"
        );

        for(uint256 i = 0; i < recipients.length; i++) {
            (bool transferSuccess, ) = recipients[i].call{value: price / recipients.length}("");
            require(
                transferSuccess,
                "ShrugSale: failed to transfer"
            );
        }

        for(uint256 i = 0; i < _count; i++) {
            token.mint(msg.sender);
        }

        emit TokenBought(msg.sender, token.maxSupply() + _count - token.totalSupply(), token.maxSupply() + 1 - token.totalSupply(), price, "ETH");
    }

    /**
     * @dev Buy Function in USDT
     * @param _count Count of tokens to buy
     */
    function buyInUSDT(uint256 _count) external nonReentrant {
        require(
            _count < 100,
            "ShrugSale: Count should be less than 100"
        );
        require(
            (token.totalSupply() + _count) <= token.maxSupply(),
            "ShrugSale: All tokens are minted"
        );

        uint256 price = getPrice(_count, 1);
        require(
            USDTToken.balanceOf(msg.sender) >= price,
            "ShrugSale: Caller does not have enough USDT balance"
        );
        require(
            USDTToken.allowance(msg.sender, address(this)) >= price,
            "ShrugSale: Caller has not allowed enough USDT balance"
        );

        for(uint256 i = 0; i < recipients.length; i++) {
            bool transferSuccess = USDTToken.transferFrom(msg.sender, recipients[i], price / recipients.length);
            require(
                transferSuccess,
                "ShrugSale: failed to transfer"
            );
        }

        for(uint256 i = 0; i < _count; i++) {
            token.mint(msg.sender);
        }

        emit TokenBought(msg.sender, token.maxSupply() + _count - token.totalSupply(), token.maxSupply() + 1 - token.totalSupply(), price, "USDT");
    }

    /**
     * @dev Buy Function in STMX
     * @param _count Count of tokens to buy
     */
    function buyInSTMX(uint256 _count) external nonReentrant {
        require(
            _count < 100,
            "ShrugSale: Count should be less than 100"
        );
        require(
            (token.totalSupply() + _count) <= token.maxSupply(),
            "ShrugSale: All tokens are minted"
        );

        uint256 price = getPrice(_count, 2);
        require(
            STMXToken.balanceOf(msg.sender) >= price,
            "ShrugSale: Caller does not have enough STMX balance"
        );
        require(
            STMXToken.allowance(msg.sender, address(this)) >= price,
            "ShrugSale: Caller has not allowed enough STMX balance"
        );

        for(uint256 i = 0; i < recipients.length; i++) {
            bool transferSuccess = STMXToken.transferFrom(msg.sender, recipients[i], price / recipients.length);
            require(
                transferSuccess,
                "ShrugSale: failed to transfer"
            );
        }

        for(uint256 i = 0; i < _count; i++) {
            token.mint(msg.sender);
        }

        emit TokenBought(msg.sender, token.maxSupply() + _count - token.totalSupply(), token.maxSupply() + 1 - token.totalSupply(), price, "STMX");
    }

    /**
     * @dev Public get price
     * @param _count Count of tokens which wanna get the price of
     */
    function getPrice(uint256 _count, uint256 currency) public view returns (uint256) {
        require(
            _count < 100,
            "ShrugSale: Count should be less than 100"
        );
        uint256 price;
        for(uint256 i = 0; i < _count; i++) {
            price += calculatePrice(token.totalSupply() + i, currency);
        }

        return price;
    }

    /**
     * @dev Owner can set USDT token contract
     * @param _addr address of USDT token
     */
    function setUSDTTokenContract(address _addr) public onlyOwner {
        USDTToken = IERC20(address(_addr));
    }

    /**
     * @dev Owner can set STMX token contract
     * @param _addr address of STMX token
     */
    function setSTMXTokenContract(address _addr) public onlyOwner {
        STMXToken = IERC20(address(_addr));
    }
}