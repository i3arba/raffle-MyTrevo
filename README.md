MyRaffle -> [MyTrevo](https://mytrevo.xyz)

NOTE: If you're not interested in reading about the misadventures of a beginner, feel free to skip to Languages.

##

The lottery protocol was my first project in Solidity. Up until then, I had only been following video tutorials in search of the necessary basic learning. The idea for creating the study protocol came from Bozz, as well as the guidelines for it.

After three weeks of studying everything I could find about Solidity, I began the project. From 06/30/2023 to 08/14/2023, I dedicated, on average, 6 hours a day. Exploring everything that could help me accomplish the mission I was given.

The biggest challenge was the CCIP, by far. Everything else I found ample help on the internet and also from Bozz. However, CCIP had just been released, and therefore, there was no content about it other than the Chainlink documentation.

"Beginner" relying solely on documentation sometimes doesn't work out very well, right? But as they say, a mission given is a mission accomplished! I dissected the CCIP and implemented it in the protocol!

After the project was delivered, Bozz informed me that this was a 'real' project and that, after adjustments, it would become the MyTrevo.yxz protocol that is now active and working as expected.

##

<h3 align="left"> 👩‍💻 Languages that I used </h3>
<div style="display: inline_block" align="left">
  <img align="center" alt="Barba-Solidity" height="30" width="80" src="https://img.shields.io/badge/Solidity-e6e6e6?style=for-the-badge&logo=solidity&logoColor=black">
  <img align="center" alt="Barba-Js" height="30" width="40" src="https://raw.githubusercontent.com/devicons/devicon/master/icons/javascript/javascript-plain.svg">
</div>

<h3 align="left"> 🛠️ Tools </h3>
<div style="display: inline_block" align="left">
  <img align="center" alt="Barba-Chainlink" height="30" width="100" src="https://img.shields.io/badge/chainlink-375BD2?style=for-the-badge&logo=chainlink&logoColor=white"> - CCIP & VRF
</div>

<h3 align="left"> 📄 About the project - [Summary] </h3>
MyRaffle or MyTrevo, as it's named, is a lottery protocol where any individual can register and create lotteries on the platform. Lotteries can involve:
- Stablecoins
- NFTs on Polygon or Ethereum. 

When creating the lottery, the owner defines:
* Period;
   * It needs to be deposited immediately after the creation of the lottery;
* Prize;
* Soft cap;

At the end of the period, if the softcap is reached, the lottery is conducted via Chainlink VRF.
Once the winner is chosen, if the prize is on the Polygon network [project's network], the payment is made instantly. However, if the prize is an NFT on Ethereum, the CCIP on the Polygon network notifies the CCIP on the Ethereum network, and from there, the prize is paid to the winner.
