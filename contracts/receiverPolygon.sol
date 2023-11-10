// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
error NothingToWithdraw();
error FailedToWithdrawEth(address owner, address target, uint256 value);
error DestinationChainNotWhitelisted(uint64 destinationChainSelector);
error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error SenderNotWhitelisted(address sender);

contract ReceiverPolygon is CCIPReceiver, Ownable{

  bytes32 private lastReceivedMessageId;
  string private lastReceivedText;

  mapping(uint64 => bool) public whitelistedDestinationChains;
  mapping(uint64 => bool) public whitelistedSourceChains;
  mapping(address => bool) public whitelistedSenders;


  modifier onlyWhitelistedDestinationChain(uint64 _destinationChainSelector) {
    if (!whitelistedDestinationChains[_destinationChainSelector])
      revert DestinationChainNotWhitelisted(_destinationChainSelector);
    _;
  }

  event MessageSent(bytes32 indexed messageId, uint64 indexed destinationChainSelector, address receiver, bytes _data, address feeToken, uint256 fees);
  event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text, address token, uint256 tokenAmount);

  LinkTokenInterface linkToken;

  constructor(address _router, address _link) CCIPReceiver(_router){ //0x70499c328e1E2a3c41108bd3730F6670a44595D1 Mumbai
    linkToken = LinkTokenInterface(_link); //0x326C977E6efc84E512bB9C30f76E30c160eD06FB Mumbai
  }

  receive() external payable {}

  function send(uint64 _destinationChainSelector, address _receiver, bytes memory _data) external onlyOwner onlyWhitelistedDestinationChain(_destinationChainSelector) returns (bytes32 messageId){
    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
      _receiver,
      _data,
      address(linkToken)
    );

    IRouterClient router = IRouterClient(this.getRouter());

    uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

    if (fees > linkToken.balanceOf(address(this)))
      revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);

    linkToken.approve(address(router), fees);

    messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

    emit MessageSent(messageId, _destinationChainSelector, _receiver, _data, address(0), fees);

    return messageId;
  }

  function _buildCCIPMessage(address _receiver, bytes memory _data, address _feeTokenAddress) internal pure returns (Client.EVM2AnyMessage memory) {
    Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
      receiver: abi.encode(_receiver),
      data: abi.encode(_data),
      tokenAmounts: new Client.EVMTokenAmount[](0),
      extraArgs:  Client._argsToBytes(
          Client.EVMExtraArgsV1({gasLimit: 800_000, strict: false})
      ),
      feeToken: _feeTokenAddress
    });
    return evm2AnyMessage;
  }

  function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override{
    lastReceivedMessageId = any2EvmMessage.messageId;
    lastReceivedText = abi.decode(any2EvmMessage.data, (string));

    emit MessageReceived(any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)), abi.decode(any2EvmMessage.data, (string)), any2EvmMessage.destTokenAmounts[0].token, any2EvmMessage.destTokenAmounts[0].amount);
  }

  function withdraw(address _beneficiary) public onlyOwner {
    uint256 amount = address(this).balance;

    if (amount == 0) revert NothingToWithdraw();

    (bool sent, ) = _beneficiary.call{value: amount}("");

    if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
  }

  function withdrawToken(address _beneficiary, address _token) public onlyOwner {
    uint256 amount = IERC20(_token).balanceOf(address(this));

    if (amount == 0) revert NothingToWithdraw();

    IERC20(_token).transfer(_beneficiary, amount);
  }

  function whitelistDestinationChain(uint64 _destinationChainSelector) external onlyOwner {
    whitelistedDestinationChains[_destinationChainSelector] = true;
  }

  function denylistDestinationChain(uint64 _destinationChainSelector) external onlyOwner {
    whitelistedDestinationChains[_destinationChainSelector] = false;
  }
  
}