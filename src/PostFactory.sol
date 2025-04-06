// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Post } from "src/Post.sol";

contract PostFactory {
    address public immutable relayer;
    address public immutable identityVerificationHub;

    uint256 public numOfPost;

    mapping(uint256 postId => address verifier) public verifiers;

    event PostCreated(uint256 postId, address postAddress);

    error InvalidMsgSender(address);

    constructor(address _relayer, address _identityVerificationHub) {
        relayer = _relayer;
        identityVerificationHub = _identityVerificationHub;
    }

    modifier onlyRelayer() {
        require(msg.sender == relayer, InvalidMsgSender(msg.sender));
        _;
    }

    function createPost(
        uint256 _scope,
        bool _olderThanEnabled,
        uint256 _olderThan,
        string memory _name,
        string memory _symbol,
        string memory _gender,
        string memory _nationality
    ) external onlyRelayer returns (uint256 postId, address postAddress) {
        postId = numOfPost++;
        postAddress = address(
            new Post(
                identityVerificationHub,
                _scope,
                _olderThanEnabled,
                _olderThan,
                // false,
                // [uint256(0), uint256(0), uint256(0), uint256(0)],
                // [false, false, false],
                relayer,
                _name,
                _symbol,
                _gender,
                _nationality
            )
        );

        verifiers[postId] = postAddress;

        emit PostCreated(postId, postAddress);
    }
}
