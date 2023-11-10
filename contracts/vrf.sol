// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFChainLink is VRFConsumerBaseV2 {

  event RequestSent(uint256 requestId, uint32 numWords, uint256 totalPlayers);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint randomValue);
  event RandomValueUpdated(uint256 randomValue);

  struct RequestStatus {
    bool fulfilled;
    bool exists;
    uint256[] randomWords;
    uint256 randomValue;
  }

  mapping(uint256 => RequestStatus) public s_requests;
  VRFCoordinatorV2Interface COORDINATOR;

  address public owner;
  uint256 private randomValue;
  mapping(uint256 => uint256) public requestIdToTotalPlayers;

  uint64 s_subscriptionId;
  uint256[] public requestIds;
  uint256 public lastRequestId;

  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords = 1;

  constructor()
    VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
  {
    COORDINATOR = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
    s_subscriptionId = 5689;
    owner = msg.sender;
  }

  function requestRandomWords(uint256 thisRaffleTotalPlayers) external onlyOwner returns (uint256 requestId) {
    requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    s_requests[requestId] = RequestStatus({ randomWords: new uint256[](0), exists: true, fulfilled: false, randomValue: 0});

    requestIds.push(requestId);
    lastRequestId = requestId;

    requestIdToTotalPlayers[requestId] = thisRaffleTotalPlayers;

    emit RequestSent(requestId, numWords, thisRaffleTotalPlayers);
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    require(s_requests[_requestId].exists, "request not found");
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWords = _randomWords ;
    s_requests[_requestId].randomValue = (_randomWords[0] % requestIdToTotalPlayers[_requestId])+1;

    emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].randomValue);
  }

  function getRequestStatus( uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords, uint256 _randomValue) {
    require(s_requests[_requestId].exists, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomWords, request.randomValue);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable: caller is not the owner");
    _;
  }
  
}
