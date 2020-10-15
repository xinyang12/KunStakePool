const { expect } = require("chai");
const { BN, time } = require('@openzeppelin/test-helpers');

const almostEqualDiv1e18 = function (expectedOrig, actualOrig) {
    const _1e18 = new BN('10').pow(new BN('18'));
    const expected = expectedOrig.div(_1e18);
    const actual = actualOrig.div(_1e18);
    this.assert(
        expected.eq(actual) ||
        expected.addn(1).eq(actual) || expected.addn(2).eq(actual) ||
        actual.addn(1).eq(expected) || actual.addn(2).eq(expected),
        'expected #{act} to be almost equal #{exp}',
        'expected #{act} to be different from #{exp}',
        expectedOrig.toString(),
        actualOrig.toString(),
    );
};

require('chai').use(function (chai, utils) {
    chai.Assertion.overwriteMethod('almostEqualDiv1e18', function (original) {
        return function (value) {
            if (utils.flag(this, 'bignumber')) {
                var expected = new BN(value);
                var actual = new BN(this._obj);
                almostEqualDiv1e18.apply(this, [expected, actual]);
            } else {
                original.apply(this, arguments);
            }
        };
    });
});

async function timeIncreaseTo(seconds) {
    const delay = 10 - new Date().getMilliseconds();
    await new Promise(resolve => setTimeout(resolve, delay));
    await time.increaseTo(seconds);
}

let KunStakePool;
let Kun;

let pool;
let kun;

describe("KunStakePool contract", function () {
    beforeEach(async function () {
        KunStakePool = await ethers.getContractFactory("KunStakePool");
        Kun = await ethers.getContractFactory("MockERC20");

        pool = await KunStakePool.deploy();
        kun = await Kun.deploy("Kun", "Kun");

        await pool.deployed();
        await kun.deployed();

        const [owner, addr1] = await ethers.getSigners();

        let dw = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48];
        // dw = [1, 2];
        // let totalReward = [14492.1875, 59539.7954620912, 153355.390717041, 221980.80830142, 285849.121404049, 305075.832017036, 319853.113168438, 335576.536862082, 320511.237607537, 332955.196368393, 313730.331175678, 324737.169945615, 306828.973948669, 322592.312485282, 298729.703890986, 312247.222992053, 282198.387507057, 293239.399418271, 257009.812150207, 265491.135951164, 223349.446360128, 229351.962731056, 192794.326625041, 197035.801810792, 179631.718998573, 183156.99148392, 164150.953802339, 166982.557755429, 146476.071147308, 148654.902705625, 126778.272591068, 128363.000998456, 124768.836970499, 126318.673873735, 122457.641804771, 123865.904685525, 113033.696683923, 114206.421287019, 102879.001869669, 103830.632636963, 90630.1111254964, 91355.1520145004, 77697.5567883326, 78222.0152966539, 64166.6779925162, 64519.594721475, 57502.3556183019, 57782.6796019411];
        let totalReward = [web3.utils.toWei('1000'), web3.utils.toWei('2000'), web3.utils.toWei('3000'), web3.utils.toWei('4000'), web3.utils.toWei('5000'), web3.utils.toWei('6000'), web3.utils.toWei('7000'), web3.utils.toWei('8000'), web3.utils.toWei('9000'), web3.utils.toWei('10000'), web3.utils.toWei('11000'), web3.utils.toWei('12000'), web3.utils.toWei('13000'), web3.utils.toWei('14000'), web3.utils.toWei('15000'), web3.utils.toWei('16000'), web3.utils.toWei('17000'), web3.utils.toWei('18000'), web3.utils.toWei('19000'), web3.utils.toWei('20000'), web3.utils.toWei('21000'), web3.utils.toWei('22000'), web3.utils.toWei('23000'), web3.utils.toWei('24000'), web3.utils.toWei('25000'), web3.utils.toWei('26000'), web3.utils.toWei('27000'), web3.utils.toWei('28000'), web3.utils.toWei('29000'), web3.utils.toWei('30000'), web3.utils.toWei('31000'), web3.utils.toWei('32000'), web3.utils.toWei('33000'), web3.utils.toWei('34000'), web3.utils.toWei('35000'), web3.utils.toWei('36000'), web3.utils.toWei('37000'), web3.utils.toWei('38000'), web3.utils.toWei('39000'), web3.utils.toWei('40000'), web3.utils.toWei('41000'), web3.utils.toWei('42000'), web3.utils.toWei('43000'), web3.utils.toWei('44000'), web3.utils.toWei('45000'), web3.utils.toWei('46000'), web3.utils.toWei('47000'), web3.utils.toWei('48000')];
        let stakeTarget = [web3.utils.toWei('1000'), web3.utils.toWei('2000'), web3.utils.toWei('3000'), web3.utils.toWei('4000'), web3.utils.toWei('5000'), web3.utils.toWei('6000'), web3.utils.toWei('7000'), web3.utils.toWei('8000'), web3.utils.toWei('9000'), web3.utils.toWei('10000'), web3.utils.toWei('11000'), web3.utils.toWei('12000'), web3.utils.toWei('13000'), web3.utils.toWei('14000'), web3.utils.toWei('15000'), web3.utils.toWei('16000'), web3.utils.toWei('17000'), web3.utils.toWei('18000'), web3.utils.toWei('19000'), web3.utils.toWei('20000'), web3.utils.toWei('21000'), web3.utils.toWei('22000'), web3.utils.toWei('23000'), web3.utils.toWei('24000'), web3.utils.toWei('25000'), web3.utils.toWei('26000'), web3.utils.toWei('27000'), web3.utils.toWei('28000'), web3.utils.toWei('29000'), web3.utils.toWei('30000'), web3.utils.toWei('31000'), web3.utils.toWei('32000'), web3.utils.toWei('33000'), web3.utils.toWei('34000'), web3.utils.toWei('35000'), web3.utils.toWei('36000'), web3.utils.toWei('37000'), web3.utils.toWei('38000'), web3.utils.toWei('39000'), web3.utils.toWei('40000'), web3.utils.toWei('41000'), web3.utils.toWei('42000'), web3.utils.toWei('43000'), web3.utils.toWei('44000'), web3.utils.toWei('45000'), web3.utils.toWei('46000'), web3.utils.toWei('47000'), web3.utils.toWei('48000')];
        let sTime = 1604160000;
        let startTime = [];
        for (let i = 0; i < 48; ++i) {
            startTime.push(sTime + i * 14 * 24 * 3600);
        }

        await pool.initialize(owner.getAddress(), kun.address, Number(sTime));
        await pool.setDWInfo(dw, startTime, stakeTarget, totalReward);
        await pool.setFirstDWRewardRate();

        kun._mint(owner.getAddress(), web3.utils.toWei('100000000'));
        kun.approve(pool.address, web3.utils.toWei('100000000'));

        kun._mint(addr1.getAddress(), web3.utils.toWei('100000000'));
        kun.connect(addr1).approve(pool.address, web3.utils.toWei('100000000'));

        kun._mint(pool.address, web3.utils.toWei('100000000'));
    });

    it("initialize", async function () {
        const [owner] = await ethers.getSigners();

        // await pool.initialize(owner.getAddress(), kun.address, 1602080538);
        expect(await pool.owner()).to.equal(await owner.getAddress());
        expect(await pool.kun()).to.equal(kun.address);
        expect(await pool.startTime()).to.equal(1604160000);
        expect(await pool.periodFinish()).to.equal(1604160000 + 672 * 24 * 3600);
    });

    it("getDoubleWeekNumber", async function () {
        const [owner] = await ethers.getSigners();

        expect(await pool.getDoubleWeekNumber(1604160000)).to.equal(1);
        expect(await pool.getDoubleWeekNumber(1604160000 + 14 * 24 * 3600)).to.equal(2);
        expect(await pool.getDoubleWeekNumber(1604160000 + 14 * 24 * 7200)).to.equal(3);
    });

    it("stake test1", async function () {
        const [owner, addr1] = await ethers.getSigners();
        let sTime = 1604160000;
        await timeIncreaseTo(sTime);

        // await pool.stake(web3.utils.toWei('100'));
        // await time.increase(7 * 24 * 3600);
        // // console.log("-------- second time ------");
        // await pool.stake(web3.utils.toWei('100'));
        // await pool.connect(addr1).stake(web3.utils.toWei('200'));
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('500'));

        // await time.increase(7 * 24 * 3600);
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('750'));
        // expect((await pool.readEarned(addr1.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('250'));
        // // await pool.connect(addr1).stake(web3.utils.toWei('200'));
        // await pool.stake(web3.utils.toWei('100'));
        // await time.increase(14 * 24 * 3600);
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('1230'));
        // expect((await pool.readEarned(addr1.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('570'));
        // await pool.withdraw(web3.utils.toWei('300'));
        // await time.increase(14 * 24 * 3600);
        // expect((await pool.readEarned(addr1.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('1320'));



        // await pool.stake(web3.utils.toWei('100'));
        // await time.increase(7 * 24 * 3600);
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('500'));
        // await pool.connect(addr1).stake(web3.utils.toWei('100'));
        // await time.increase(7 * 24 * 3600);
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('750'));
        // expect((await pool.readEarned(addr1.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('250'));
        // await time.increase(21 * 24 * 3600);
        // console.log((await pool.readEarned(owner.getAddress())).toString());
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('950'));
        // expect((await pool.readEarned(addr1.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('450'));
        // // await time.increase(14 * 24 * 3600);
        // await pool.stake(web3.utils.toWei('200'));
        // await pool.connect(addr1).stake(web3.utils.toWei('200'));
        // await time.increase(14 * 24 * 3600);
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('1300'));
        // expect((await pool.readEarned(addr1.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('800'));


        // await pool.stake(web3.utils.toWei('100'));
        // await time.increase(7 * 24 * 3600);
        // expect((await pool.readEarned(owner.getAddress())).toString()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('500'));
        // await pool.connect(addr1).stake(web3.utils.toWei('100'));
        // await time.increase(14 * 24 * 3600);
        // await pool.withdraw(web3.utils.toWei('100'));
        // await pool.connect(addr1).withdraw(web3.utils.toWei('100'));
        // await time.increase(28 * 24 * 3600);
        // await pool.getReward();


        await pool.register();
        const votesOf1 = await pool.votesOf(owner.getAddress());
        console.log(votesOf1.toString());
        await pool.stake(web3.utils.toWei('1.01'));
        await pool.connect(addr1).stake(web3.utils.toWei('2'))
        await pool.propose(owner.getAddress(), "ha");
        const votesOf2 = await pool.votesOf(owner.getAddress());
        console.log(votesOf2.toString());
        const proposalCount = await pool.proposalCount();
        console.log("proposalCount is ", proposalCount.toString());
        await pool.connect(addr1).voteFor(proposalCount - 1);
        await pool.connect(addr1).voteAgainst(proposalCount - 1);
        const res = await pool.getVoterStats(0, owner.getAddress());
        console.log(res[0].toString());
        console.log(res[1].toString());
        // const lastBlock = await time.latestBlock();
        // await time.advanceBlockTo(lastBlock.addn(17279));
        // await pool.connect(addr1).withdraw(web3.utils.toWei('2'));
        // console.log(res[2].toString());

        // 17279不能通过，17280可以通过。通过测试！
        // advanceBlock 太多了，测试会很慢
        // const lastBlock = await time.latestBlock();
        // await time.advanceBlockTo(lastBlock.addn(17279));
        // await pool.withdraw(web3.utils.toWei('1.01'));

    });
});