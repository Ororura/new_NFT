// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/ERC20.sol";
import "contracts/ERC1155.sol";

interface IMint is IERC20 {
    function getReward(address _to) external;

    function decimals() external view returns (uint8);

    function sendTokens(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

contract NFT is ERC1155("") {
    address owner;
    uint256 dec;
    IMint token;

    constructor(address _contractAddress) {
        owner = msg.sender;
        token = IMint(_contractAddress);
        dec = 10**token.decimals();

        createNFT(unicode"Герда в профиль", unicode"Скучающая хаски по имени Герда", "husky_nft1.png", 7, 2000);
        createNFT(unicode"Герда на фрилансе", unicode"Герда релизнула новый проект", "husky_nft2.png", 5, 5000);
        createNFT(unicode"Новогодняя Герда", unicode"Герда ждет боя курантов", "husky_nft3.png", 2, 3500);
        createNFT(
            unicode"Герда в отпуске",
            unicode"Приехала отдохнуть после тяжелого проекта",
            "husky_nft4.png",
            6,
            4000
        );
    }

    struct AssetNFT {
        uint256 id;
        string name;
        string desc;
        string photo;
        int256 coll;
        uint256 amount;
        uint256 price;
        uint256 dateCreate;
    }

    struct Coll {
        uint256 id;
        string name;
        string desc;
        uint256[] ids;
        uint256[] amount;
        bool deleted;
    }

    struct Sales {
        uint256 id;
        address owner;
        uint256 nft;
        uint256 amount;
        uint256 price;
    }

    struct Ref {
        address owner;
        string name;
        uint256 discount;
        address[] users;
    }

    struct Auc {
        uint256 id;
        uint256 coll;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 minBet;
        uint256 maxBet;
        uint256 bet;
        address leader;
        bool end;
    }

    struct Bet {
        uint id;
        address owner;
        uint256 bet;
    }

    mapping(uint256 => AssetNFT) nftMap;
    mapping(address => uint256[]) userNft;
    mapping(uint256 => bool) inColl;
    mapping(string => Ref) ref;
    mapping(address => bool) usedRef;

    AssetNFT[] nfts;
    Coll[] coll;
    Sales[] sales;
    Auc[] auc;
    Bet[] bet;

    modifier OnlyOwner() {
        require(msg.sender == owner, unicode"Вы не владелец контракта");
        _;
    }

    modifier CheckTime(uint256 _auc) {
        if (block.timestamp > auc[_auc].timeEnd) {
            auc[_auc].end = true;
            takeNFT(_auc);
        }
        _;
    }

    function stopAuc(uint256 _auc) public OnlyOwner {
        auc[_auc].end = true;
        takeNFT(_auc);
    }

    function makeBet(uint256 _auc, uint256 _bet) public CheckTime(_auc) {
        require(auc[_auc].end == false, unicode"Аукцион завершён!");
        require(block.timestamp >= auc[_auc].timeStart, unicode"Аукцион ещё не начался!");
        for (uint256 i; i < bet.length; i++) {
            if (bet[i].owner == msg.sender) {
                bet[i].bet += _bet * dec;
                require(bet[i].bet >= auc[_auc].bet, unicode"Текущая ставка выше вашей");
                auc[_auc].bet = bet[i].bet;
                auc[_auc].leader = msg.sender;
                if (bet[i].bet >= auc[_auc].maxBet) {
                    auc[_auc].end = true;
                    takeNFT(_auc);
                }
                return;
            }
        }
        require(_bet * dec > auc[_auc].minBet, unicode"Минимальная ставка выше вашей");
        require(_bet * dec > auc[_auc].bet, unicode"Текущая ставка выше вашей");

        auc[_auc].leader = msg.sender;
        auc[_auc].bet = _bet * dec;
        bet.push(Bet(_auc, msg.sender, _bet * dec));
        if (_bet * dec >= auc[_auc].maxBet) {
            auc[_auc].end = true;
            takeNFT(_auc);
        }
    }

    function takeNFT(uint256 _auc) public CheckTime(_auc) {
        require(auc[_auc].end == true, unicode"Аукцион ещё не завершён!");
        for (uint256 i; i < coll[auc[_auc].coll].ids.length; i++) {
            transferNFT(owner, auc[_auc].leader, coll[auc[_auc].coll].ids[i], coll[auc[_auc].coll].amount[i]);
            inColl[coll[auc[_auc].coll].ids[i]] = false;
            coll[auc[_auc].coll].deleted = true;
        }
    }

    function transferNFT(
        address _from,
        address _to,
        uint256 _nft,
        uint256 _amount
    ) public {
        require(balanceOf(_from, _nft) >= _amount, unicode"У вас недостаточно NFT");
        _safeTransferFrom(_from, _to, _nft, _amount, "");
        for (uint256 i; i < userNft[_to].length; i++) {
            if (userNft[_to][i] == _nft) {
                return;
            }
        }
        userNft[_to].push(_nft);
    }

    function startAuc(
        uint256 _coll,
        uint256 _timeStart,
        uint256 _timeEnd,
        uint256 _minBet,
        uint256 _maxBet
    ) public OnlyOwner {
        auc.push(
            Auc(
                auc.length,
                _coll,
                block.timestamp + (_timeStart * 60),
                block.timestamp + (_timeEnd * 60),
                _minBet * dec,
                _maxBet * dec,
                _minBet * dec,
                msg.sender,
                false
            )
        );
    }

    function changePrice(uint256 _id, uint256 _price) public {
        require(sales[_id].owner == msg.sender, unicode"Вы не владелец этого лота!");
        sales[_id].price = _price * dec;
    }

    function buyNFT(
        uint256 _id,
        uint256 _amount,
        string calldata _wallet
    ) public {
        string memory refName = string.concat("2024-", _wallet[2:6], "PROFI");
        uint256 totalPrice = (sales[_id].price * _amount) -
            ((sales[_id].price * _amount * ref[refName].discount) / 100);
        require(token.balanceOf(msg.sender) >= totalPrice, unicode"У вас недостаточно токенов для покупки!");
        require(sales[_id].amount >= _amount, unicode"У продавца недостаточно NFT!");
        transferNFT(sales[_id].owner, msg.sender, sales[_id].nft, _amount);
        sales[_id].amount -= _amount;
    }

    function useRef(string memory _ref) public {
        require(ref[_ref].owner != msg.sender, unicode"Вы не можете использовать свой реферал!");
        require(usedRef[msg.sender] != true, unicode"Вы уже использовали реферал!");
        bool found = false;
        for (uint256 i; i < ref[_ref].users.length; i++) {
            if (ref[_ref].users[i] == msg.sender) {
                found = true;
            }
        }
        require(found == true, unicode"Вас нет в вайтлисте");
        usedRef[msg.sender] = true;
        token.getReward(msg.sender);
        if (ref[_ref].discount < 3) {
            ref[_ref].discount++;
        }
    }

    function addUserRef(address _user, string calldata _wallet) public {
        string memory name = string.concat("2024-", _wallet[2:6], "PROFI");
        require(ref[name].owner == msg.sender, unicode"Вы не владелец реферала!");
        ref[name].users.push(_user);
    }

    function createRef(string calldata _wallet) public {
        string memory name = string.concat("2024-", _wallet[2:6], "PROFI");
        require(ref[name].owner == address(0), unicode"У вас уже есть реферал!");
        address[] memory users;
        ref[name] = Ref(msg.sender, name, 0, users);
    }


    function sellNFT(
        uint256 _nft,
        uint256 _amount,
        uint256 _price
    ) public {
        require(balanceOf(msg.sender, _nft) >= _amount, unicode"У вас недостаточно NFT для продажи");
        require(inColl[_nft] != true, unicode"Вы не можете продавать NFT из коллекции");
        sales.push(Sales(sales.length, msg.sender, _nft, _amount, _price * dec));
    }

    function createColl(
        string memory _name,
        string memory _desc,
        uint256[] memory _ids,
        uint256[] memory _amount
    ) public OnlyOwner {
        coll.push(Coll(coll.length, _name, _desc, _ids, _amount, false));
        for (uint256 i; i < _ids.length; i++) {
            require(balanceOf(owner, _ids[i]) >= _amount[i], unicode"У вас недостаточно NFT для коллекции");
            nftMap[_ids[i]].coll = int256(coll.length);
            inColl[_ids[i]] = true;
        }
    }

    function createNFT(
        string memory _name,
        string memory _desc,
        string memory _photo,
        uint256 _amount,
        uint256 _price
    ) public OnlyOwner {
        nftMap[nfts.length] = AssetNFT(nfts.length, _name, _desc, _photo, -1, _amount, _price * dec, block.timestamp);
        userNft[owner].push(nfts.length);
        _mint(owner, nfts.length, _amount, "");
        nfts.push(AssetNFT(nfts.length, _name, _desc, _photo, -1, _amount, _price * dec, block.timestamp));
    }

    function getColl() public view returns (Coll[] memory) {
        return coll;
    }

    function getSales() public view returns (Sales[] memory) {
        return sales;
    }

    function getRef(string calldata _wallet) public view returns (Ref memory) {
        string memory refName = string.concat("2024-", _wallet[2:6], "PROFI");
        return ref[refName];
    }

    function getUserNFT() public view returns (AssetNFT[] memory, uint256[] memory) {
        AssetNFT[] memory returnAssets = new AssetNFT[](userNft[msg.sender].length);
        uint256[] memory balances = new uint256[](userNft[msg.sender].length);

        for (uint256 i; i < userNft[msg.sender].length; i++) {
            returnAssets[i] = nftMap[userNft[msg.sender][i]];
            balances[i] = balanceOf(msg.sender, userNft[msg.sender][i]);
        }

        return (returnAssets, balances);
    }

    function getAuc() public view returns (Auc[] memory) {
        return auc;
    }

    function getUserBalance() public view returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    function getBet() public view returns (Bet[] memory) {
        return bet;
    }
}
