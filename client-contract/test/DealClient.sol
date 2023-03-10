// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DealClient.sol";
import { MarketTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import { serializeDealProposal, deserializeDealProposal } from "../src/Types.sol";

contract MockMarket {
    function publish_deal(bytes memory raw_auth_params, address callee) public {
        // calls standard filecoin receiver on message authentication api method number
        (bool success, ) = callee.call(abi.encodeWithSignature("handle_filecoin_method(uint64,uint64,bytes)", 0, 2643134072, raw_auth_params));
        require(success, "client contract failed to authorize deal publish");
    }
}


contract DealClientTest is Test {
    DealClient public client;
    MockMarket public relay;
    bytes testCID;
    bytes testShortCID;
    bytes testProvider;
    bytes testOtherProvider;

    function setUp() public {
        client = new DealClient();
        relay = new MockMarket();
        testCID = hex"000181E2039220206B86B273FF34FCE19D6B804EFF5A3F5747ADA4EAA22F1D49C01E52DDB7875B4B";
        testShortCID = hex"42";
        testProvider = hex"0066";
        testOtherProvider = hex"00EE";
    }

    function createDealRequest() public view returns (DealRequest memory) {
        DealRequest memory request = DealRequest({
            piece_cid: testCID,
            piece_size: 2048,
            verified_deal: false,
            label: "",
            start_epoch: 0,
            end_epoch: 0,
            storage_price_per_epoch: 0,
            provider_collateral: 0,
            client_collateral: 0,
            extra_params_version: 0,
            extra_params: ExtraParamsV1({
                location_ref: "",
                car_size: 0,
                skip_ipni_announce: false,
                remove_unsealed_copy: false
            })
        });
        return request;
    }


    function testMakeDealProposal() public {
        require(client.dealsLength() == 0, "Expect no deals");
        client.makeDealProposal(createDealRequest());
        require(client.dealsLength() == 1, "Expect one deal");

        RequestId memory proposalIdSet = client.getProposalIdSet(testCID);
        require(proposalIdSet.valid, "expected to have valid Proposal");
        DealRequest memory deal = client.getDealByIndex(0);
        require(deal.piece_size == 2048, "unexpected cid size in client after setting");

        ProviderSet memory providerSet = client.getProviderSet(testCID);
        require(!providerSet.valid, "should not be valid before a cid is authorized");

        // non-added cid has expected state
        RequestId memory proposalIdSetShort = client.getProposalIdSet(testShortCID);
        require(!proposalIdSetShort.valid, "expected to have valid Proposal");
        ProviderSet memory providerSetShort = client.getProviderSet(testShortCID);
        require(!providerSetShort.valid, "should not be valid before a cid is authorized");

    }


    function testGetDealProposal() public {
        bytes32 requestId = client.makeDealProposal(createDealRequest());

        bytes memory cborDealProposal = client.getDealProposal(requestId);
        MarketTypes.DealProposal memory dp = deserializeDealProposal(cborDealProposal);
        require(keccak256(testCID) == keccak256(dp.piece_cid.data));
//        require(dp.provider == FilAddresses.fromActorID(0));

        // Expect a revert for an unknown proposal ID
        vm.expectRevert();
        client.getDealProposal(bytes32(0));
    }

/*

    function testMockMarket() public {
        client.addCID(testCID, 2048);
        bytes memory messageAuthParams = hex"8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f4420068420066656c6162656c0a1a0008ca0a42000a42000a42000a";
        address a = address(client);

        relay.publish_deal(messageAuthParams, a);
        require(client.cidProviders(testCID, testProvider), "test provider should be added");

        // publishing again goes against client policy
        vm.expectRevert(bytes("client contract failed to authorize deal publish"));
        relay.publish_deal(messageAuthParams, a);
    }
    function testAuthorizeData() public {
        // add cid, authorize data, wrong size should fail
        client.addCID(testCID, 2048);
        vm.expectRevert(bytes("data size must match expected"));
        uint wrongSize = 4096;
        client.authorizeData(testCID, testProvider, wrongSize);

        // successful authorization
        client.authorizeData(testCID, testProvider, 2048);

        // authorize again should fail
        vm.expectRevert(bytes("deal failed policy check: has provider already claimed this cid?"));
        client.authorizeData(testCID, testProvider, 2048);

        // authorize with new provider should pass and both providers tracked
        client.authorizeData(testCID, testOtherProvider, 2048);
        require(client.cidProviders(testCID, testProvider), "test provider should be added");
        require(client.cidProviders(testCID, testOtherProvider), "test other provider should be added");
    }

    function testHandleFilecoinMethod() public {
        client.addCID(testCID, 2048);
        // message auth params for a deal with this cid 
        bytes memory messageAuthParams = hex"8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f4420068420066656c6162656c0a1a0008ca0a42000a42000a42000a";
        client.handle_filecoin_method(0, client.AUTHORIZE_MESSAGE_METHOD_NUM(), messageAuthParams);

        // authorization should be added 
        require(client.cidProviders(testCID, testProvider), "test provider should be added");
    }
}



contract ParseCBORTest is Test {

    function bytes_equal(bytes memory a, bytes memory b) pure public returns(bool) {
        return keccak256(a) == keccak256(b);
    }

    function test_specific_cbor_parsing() view external {
        // generated from a builtin actors test, valid cbor, some fields simplified
        bytes memory dealProposal = hex"8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f4420068420066656c6162656c0a1a0008ca0a42000a42000a42000a";
        bytes memory messageAuthParams = hex"8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f4420068420066656c6162656c0a1a0008ca0a42000a42000a42000a";

        bytes memory parsedOutDealProposal = this.parseAuthenticateMessageParams(messageAuthParams);
        assert(bytes_equal(dealProposal, parsedOutDealProposal));
        (bytes memory rawcid, bytes memory provider, uint size) = this.parseDealProposal(parsedOutDealProposal);
        assert(bytes_equal(rawcid, hex"000181E2039220206B86B273FF34FCE19D6B804EFF5A3F5747ADA4EAA22F1D49C01E52DDB7875B4B"));
        assert(bytes_equal(provider, hex"0066"));
        assert(size == 2048);
    }

    function parseAuthenticateMessageParams(bytes calldata bs) external pure returns(bytes memory) {
        return specific_authenticate_message_params_parse(bs);
    }

    function parseDealProposal(bytes calldata bs) external pure returns(bytes calldata rawcid, bytes calldata provider, uint size){
        return specific_deal_proposal_cbor_parse(bs);
    }

    function testCBORHeadersInts() view external {
        // setup test cases
        // subset taken from https://www.rfc-editor.org/rfc/rfc8949.html appendix A
        // positive
        bytes memory zero = hex"00";
        bytes memory twentythree = hex"17";
        bytes memory twentyfour = hex"1818";
        bytes memory thousand = hex"1903e8";
        bytes memory million = hex"1a000f4240";
        bytes memory maxint = hex"1bffffffffffffffff";
        

        // negative
        bytes memory negativethousand = hex"3903e7";

        uint8 maj;
        uint64 extra;
        uint byteIdx;

        (maj, extra, byteIdx) = this.parseCBORHeader(zero, 0);
        assert(maj == MajUnsignedInt);
        assert(extra == 0);
        assert(byteIdx == 1);

        (maj, extra, byteIdx) = this.parseCBORHeader(twentythree, 0);
        assert(maj == MajUnsignedInt);
        assert(extra == 23);
        assert(byteIdx == 1);

        (maj, extra, byteIdx) = this.parseCBORHeader(twentyfour, 0);
        assert(maj == MajUnsignedInt);
        assert(extra == 24);
        assert(byteIdx == 2);

        (maj, extra, byteIdx) = this.parseCBORHeader(thousand, 0);
        assert(maj == MajUnsignedInt);
        assert(extra == 1000);
        assert(byteIdx == 3);

        (maj, extra, byteIdx) = this.parseCBORHeader(million, 0);
        assert(maj == MajUnsignedInt);
        assert(extra == 1000000);
        assert(byteIdx == 5);

        (maj, extra, byteIdx) = this.parseCBORHeader(maxint, 0);
        assert(maj == MajUnsignedInt);
        assert(extra == 18446744073709551615);
        assert(byteIdx == 9);

        (maj, extra, byteIdx) = this.parseCBORHeader(negativethousand, 0);
        assert(maj == MajNegativeInt);
        assert(extra == 999);
        assert(byteIdx == 3);

        bytes memory testesttest = hex"5828000181E2039220206B86B273FF34FCE19D6B804EFF5A3F5747ADA4EAA22F1D49C01E52DDB7875B4B";
        (maj, extra, byteIdx) = this.parseCBORHeader(testesttest, 0);


    }

    function testCBORHeadersStrings() view public {
        // text string
        bytes memory emptystring = hex"60"; 
        bytes memory charactera = hex"6161";
        bytes memory stringsayingietf = hex"6449455446";

        // byte string
        bytes memory bytessayingietf = hex"581964494554466449455446644945544664494554466449455446"; // 25 bytes of repeated h"IETF"

        uint8 maj;
        uint64 extra;
        uint byteIdx;

        (maj, extra, byteIdx) = this.parseCBORHeader(emptystring, 0);
        assert(maj == MajTextString);
        assert(extra == 0);
        assert(byteIdx == 1);

        (maj, extra, byteIdx) = this.parseCBORHeader(charactera, 0);
        assert(maj == MajTextString);
        assert(extra == 1);
        assert(byteIdx == 1);        

        (maj, extra, byteIdx) = this.parseCBORHeader(stringsayingietf, 0);
        assert(maj == MajTextString);
        assert(extra == 4);
        assert(byteIdx == 1);        

        (maj, extra, byteIdx) = this.parseCBORHeader(bytessayingietf, 0);
        assert(maj == MajByteString);
        assert(extra == 25);
        assert(byteIdx == 2);     

    }

    function testCBORHeadersOthers() public view {
        // other
        bytes memory infinity = hex"f97c00"; // (Maj7, 31744, 3)
        bytes memory boolfalse = hex"f4"; // (Maj7, 20, 1)
        bytes memory big = hex"c249010000000000000000"; //tagged big int 18446744073709551616 (Maj6, 2, 1)
        // data structs 
        bytes memory emptyarray = hex"80";
        bytes memory emptymap = hex"a0"; 
        bytes memory bigmap = hex"a56161614161626142616361436164614461656145"; //{"a": "A", "b": "B", "c": "C", "d": "D", "e": "E"}
        bytes memory bigarray = hex"981A000102030405060708090a0b0c0d0e0f101112131415161718181819"; // [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]

        uint8 maj;
        uint64 extra;
        uint byteIdx;

        (maj, extra, byteIdx) = this.parseCBORHeader(infinity, 0);
        assert(maj == MajOther);
        assert(extra == 31744);
        assert(byteIdx == 3);

        (maj, extra, byteIdx) = this.parseCBORHeader(boolfalse, 0);
        assert(maj == MajOther);
        assert(extra == 20);
        assert(byteIdx == 1);

        (maj, extra, byteIdx) = this.parseCBORHeader(big, 0);
        assert(maj == MajTag);
        assert(extra == 2);
        assert(byteIdx == 1);

        (maj, extra, byteIdx) = this.parseCBORHeader(emptyarray, 0);
        assert(maj == MajArray);
        assert(extra == 0);
        assert(byteIdx == 1);        

        (maj, extra, byteIdx) = this.parseCBORHeader(emptymap, 0);
        assert(maj == MajMap);
        assert(extra == 0);
        assert(byteIdx == 1);        

        (maj, extra, byteIdx) = this.parseCBORHeader(bigmap, 0);
        assert(maj == MajMap);
        assert(extra == 5);
        assert(byteIdx == 1);

        (maj, extra, byteIdx) = this.parseCBORHeader(bigarray, 0);
        assert(maj == MajArray);
        assert(extra == 26);
        assert(byteIdx == 2);

    }

    function parseCBORHeader(bytes calldata bs, uint start) external pure returns(uint8, uint64, uint) {
        return parse_cbor_header(bs, start);
    }

    function testSliceBytesEntry() external view {
        // setup
        bytes memory bs;
        bs = new bytes(10);
        bs[0] = 0x01;
        bs[1] = 0x02;
        bs[2] = 0x03;
        bs[3] = 0x04;
        bs[4] = 0x05;
        bs[5] = 0x06;
        bs[6] = 0x00;
        bs[7] = 0xFF;
        bs[8] = 0xE1;
        bs[9] = 0x0A;

        // uint8
        uint8 i = this.sliceUint8Bytes(bs, 0);
        require(i == 1, "unexpected uint8 sliced out");
        i = this.sliceUint8Bytes(bs, 7);
        require(i == 255);

        // uint16
        uint16 j = this.sliceUint16Bytes(bs, 0); // 0x0102 = 258
        require(j == 258, "unexpected uint16 sliced out");
        j = this.sliceUint16Bytes(bs, 8); // 0xE10A = 57610
        require(j == 57610, "unexpected uint16 sliced out");

        // uint32 and uint64
        uint32 k = this.sliceUint32Bytes(bs, 0); // 0x01020304 = 16909060
        require(k == 16909060, "unexpected uint32 sliced out");
        k = this.sliceUint32Bytes(bs, 6); // 0x00FFE10A = 16769290
        require(k == 16769290, "unexpectd uint32 sliced out");
        uint64 m = this.sliceUint64Bytes(bs, 0); // 0x01020304050600FF = 72623859790381311
        require(m == 72623859790381311, "unexpected uint64 sliced out");
    }
    */
}
