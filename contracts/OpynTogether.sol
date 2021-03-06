// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * @dev "Pseudo" smart-contract that describes the issues on the README.md
 */
contract OpynTogether {
    /**
     * @dev Struct that outlines the "Participant" in the liquidity program
     */
    struct Participant {
        address user;
        uint256 liquidityAmount;
    }
    /**
     * @dev Struct that outlines the "Position"
     * 
     * Describes a liquidity position
     */
    struct Position {
        address liquidityPool;
        uint256 timeOfExpiration;
        mapping(address => Participant) participants;
        bool open;
    }

    /**
     * @dev Mapping that contains a pair of the oToken address to a Position (if it still exists)
     */
    mapping(address => Position) public positions;
    /**
     * @dev uint256 that contains the amount of time before a liquidity provider can withdraw prior to expiration. 
     */
    uint256 public allowedTimeBeforeExpiration;
    address public admin;

    event PositionOpened(address oToken);
    event PositionClosed(address oToken);

    constructor(address _admin, uint256 _allowedTimeBeforeExpiration) {
        require(
            _admin != address(0),
            "Zero address"
        );
        admin = _admin;
        allowedTimeBeforeExpiration = _allowedTimeBeforeExpiration;
    }

    modifier onlyAdmin {
        _onlyAdmin();
        _;
    }
    modifier onlyParticipant(address _oToken) {
        _onlyParticipant(_oToken);
        _;
    }

    function openNewPosition(
        address _oToken,
        address _liquidityPool
    ) external {
        require(
            _oToken != address(0),
            "Zero address"
        );

        Position storage position = positions[_oToken];

        if(_liquidityPool == address(0)) {
            // Create a new Uniswap v1 (?) pool
        } else {
            position.liquidityPool = _liquidityPool;
        }

        //position.timeOfExpiration = make a call to the oToken and grab its expiration value
        position.open = true;
        emit PositionOpened(_oToken);
    }
    function closePosition(
        address _oToken
    )
        external onlyParticipant(_oToken)
    {
        // Require statement for oToken to check if zero address is not needed due to modifier
        Position storage position = positions[_oToken];
        require(
            position.timeOfExpiration >= block.timestamp,
            "Cannot close position"
        );
        position.open = false;

        emit PositionClosed(_oToken);
    }
    function depositIntoPosition(
        address _oToken,
        uint256 _oTokenDeposit
    )
        external onlyParticipant(_oToken)
    {
        Position storage position = positions[_oToken];

        // ERC20 transferFrom from msg.sender to liquidity pool
        position.participants[msg.sender].liquidityAmount += _oTokenDeposit;
    }
    function withdrawInPosition(
        address _oToken,
        uint256 _oTokenWithdraw
    )
        external onlyParticipant(_oToken)
    {
        Position storage position = positions[_oToken];
        
        // Make a call to withdraw _oTokenWithdraw...
        position.participants[msg.sender].liquidityAmount -= _oTokenWithdraw;
    }
    function changeAllowedTimeBeforeExpiration(
        uint256 _newTime
    )
        external onlyAdmin
    {
        allowedTimeBeforeExpiration = _newTime;
    }
    function changeAdmin(address _admin) external onlyAdmin {
        require(
            _admin != address(0),
            "Zero address"
        );
        admin = _admin;
    }
    function _onlyParticipant(address _oToken) internal view {
        require(
            positions[_oToken].participants[msg.sender].user != address(0),
            "Unauthorized (participant)"
        );
    }
    function _onlyAdmin() internal view {
        require(
            msg.sender == admin,
            "Unauthorized"
        );
    }
}