﻿using DSInternals.Common;
using DSInternals.Common.Data;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DSInternals.DataStore.Test
{
    [TestClass]
    public class DataStoreSecretDecryptorTester
    {
        [TestMethod]
        public void PasswordEncryptionKey_DataStorePEK_W2k_Decrypt()
        {
            // Win 2000 - Win 2012 R2
            byte[] encryptedPEK = "020000000100000042b1f49dbb723edff3b865a4d28e3afbf215961695225991e991d429a02ad382bd89214319f61e7eb4620e89b42ddba3d0de84c0603d6e34ae2fccf79eb9374a9a08d3b1".HexToBinary();
            byte[] bootKey = "41e34661faa0d182182f6ddf0f0ca0d1".HexToBinary();
            var pek = new DataStoreSecretDecryptor(encryptedPEK, bootKey);
            string expected = "04b7b3fd6df689af9d6837e840abdc8c";
            Assert.AreEqual(expected, pek.CurrentKey.ToHex());
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStorePEK_W2k_Encrypt()
        {
            // Win 2000 - Win 2012 R2
            byte[] encryptedPEK = "020000000100000042b1f49dbb723edff3b865a4d28e3afbf215961695225991e991d429a02ad382bd89214319f61e7eb4620e89b42ddba3d0de84c0603d6e34ae2fccf79eb9374a9a08d3b1".HexToBinary();
            byte[] bootKey = "41e34661faa0d182182f6ddf0f0ca0d1".HexToBinary();
            byte[] bootKey2 = "abcdef0123456789abcdef0123456780".HexToBinary();

            // Decrypt
            var pek = new DataStoreSecretDecryptor(encryptedPEK, bootKey);

            // Re-encrypt with a different boot key
            byte[] encryptedPEK2 = pek.ToByteArray(bootKey2);

            // And decrypt again with the new boot key
            var pek2 = new DataStoreSecretDecryptor(encryptedPEK2, bootKey2);

            // Check if the new PEK looks like the original one
            Assert.AreEqual(pek.Version, pek2.Version);
            Assert.AreEqual(pek.LastGenerated, pek2.LastGenerated);
            Assert.AreEqual(pek.EncryptionType, pek2.EncryptionType);
            Assert.AreEqual(pek.CurrentKeyIndex, pek2.CurrentKeyIndex);
            Assert.AreEqual(pek.CurrentKey.ToHex(), pek2.CurrentKey.ToHex());
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStorePEK_W2016_Decrypt()
        {
            // Win 2016 TP4+
            byte[] encryptedPEK = "03000000010000008ACED06423573C329BECD77936128FD61FD3892FAC724D4D24B2F4A5DA48A72B5472BDCB7FB6EEFA4884CDC9B2D2A835931A3E67B434DC766051A28B73DE385285B19961E0DC0CF661BA0AC3B3DD185D00000000000000000000000000000000".HexToBinary();
            byte[] bootKey = "c0f2efe014aeda56da739a22ae9e9893".HexToBinary();
            var pek = new DataStoreSecretDecryptor(encryptedPEK, bootKey);
            string expected = "6A35D3FC0E9949135463AB766CAC7DBB";
            Assert.AreEqual(expected, pek.CurrentKey.ToHex(true));
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStorePEK_W2016_Encrypt()
        {
            // Win 2016 TP4+
            byte[] encryptedPEK = "03000000010000008ACED06423573C329BECD77936128FD61FD3892FAC724D4D24B2F4A5DA48A72B5472BDCB7FB6EEFA4884CDC9B2D2A835931A3E67B434DC766051A28B73DE385285B19961E0DC0CF661BA0AC3B3DD185D00000000000000000000000000000000".HexToBinary();
            byte[] bootKey = "c0f2efe014aeda56da739a22ae9e9893".HexToBinary();
            byte[] bootKey2 = "abcdef0123456789abcdef0123456780".HexToBinary();

            // Decrypt
            var pek = new DataStoreSecretDecryptor(encryptedPEK, bootKey);

            // Re-encrypt with a different boot key
            byte[] encryptedPEK2 = pek.ToByteArray(bootKey2);

            // And decrypt again with the new boot key
            var pek2 = new DataStoreSecretDecryptor(encryptedPEK2, bootKey2);

            // Check if the new PEK looks like the original one
            Assert.AreEqual(pek.Version, pek2.Version);
            Assert.AreEqual(pek.LastGenerated, pek2.LastGenerated);
            Assert.AreEqual(pek.EncryptionType, pek2.EncryptionType);
            Assert.AreEqual(pek.CurrentKeyIndex, pek2.CurrentKeyIndex);
            Assert.AreEqual(pek.CurrentKey.ToHex(), pek2.CurrentKey.ToHex());
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStorePEK_W2019_Encrypt()
        {
            // Win 2019 RTM (Format is the same as WS 2016)
            byte[] encryptedPEK = "030000000100000065DB55C82F7AB29C7FF2CC3518C0DC00433C80629D23D64420D9264BB2FE54288C3121B396CD4DC9BF094EDCBF559DAD3545C52399B883BD0F374EEAF3FA35C71C75DD1447FD0A59C81C60F6703F9B7000000000000000000000000000000000".HexToBinary();
            byte[] bootKey = "f51aa1df3bb0175efbd6842bffba81c9".HexToBinary();
            byte[] bootKey2 = "c965a6c04ac771ae10932f25efd8d85c".HexToBinary();

            // Decrypt
            var pek = new DataStoreSecretDecryptor(encryptedPEK, bootKey);

            // Re-encrypt with a different boot key
            byte[] encryptedPEK2 = pek.ToByteArray(bootKey2);

            // Decrypt again with the new boot key
            var pek2 = new DataStoreSecretDecryptor(encryptedPEK2, bootKey2);

            // And re-encrypt with the original BootKey
            byte[] encryptedPEK3 = pek2.ToByteArray(bootKey);

            // Check if the newly encrypted PEK has the same length as the original one
            Assert.AreEqual(encryptedPEK.Length, encryptedPEK3.Length);
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStorePEK_LDS_W2012_Decrypt()
        {
            // AD LDS/ADAM
            byte[] configNCPekList = "0200000001000000a2e75ba77d90fc28ccedc89c7ab4097a9101394114c7f549105376a00fb70645408defb7d28448e0de5a0298dc90a2744a875e1a927f8f038b6ac9e7c5d67c1dbde114c4".HexToBinary();
            byte[] bootKey = "51f9a1e2282c7b7a79f0ba210d1e8ef7".HexToBinary();
            var pek = new DataStoreSecretDecryptor(configNCPekList, bootKey);

            string expected = "85f273f46d6699da896c26e359106ebc";
            Assert.AreEqual(expected, pek.CurrentKey.ToHex(false));
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStorePEK_LDS_W2019_Decrypt()
        {
            byte[] rootObjectPekList = "6d94991d9c0fe72837db099c28aa12f81ea1fc285c893f51fdd9e062d8d2a3ed6eb4ac1457e1fdd3".HexToBinary();
            byte[] schemaObjectPekList = "e657f7626023770ce6a0bc7e9a1e8468c34abf61abea225824c9e100a3e789aab2814796a5cb8b07".HexToBinary();
            byte[] configNCPekList = "0300000001000000f25b8e6b334557b94514ade0bc4c36d706b7fc0250897ce8a87f0c4edb47280303f18e4cfc4caf56fdce7eadcdae0becef361f92d7db50c69745c82604a0f52b767410638342fb66b638cd965edc90d300000000000000000000000000000000".HexToBinary();

            // Combine the fake pekLists
            byte[] bootKey = BootKeyRetriever.GetBootKey(rootObjectPekList, schemaObjectPekList);

            // Decrypt the actual pekList
            var pek = new DataStoreSecretDecryptor(configNCPekList, bootKey);

            // Perform some sanity checks
            Assert.AreEqual(PekListVersion.W2016, pek.Version);
            Assert.AreEqual(16, pek.CurrentKey.Length);
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHash_W2k_Decrypt()
        {
            // Win 2000 - Win 2012 R2
            byte[] blob = "1100000000000000133c2e574dfc2df435671649180617cfb3cc9ef487c99b1d6cda3fb410a021f5".HexToBinary();
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfb0b0f777efcece0100000000010000000000000004b7b3fd6df689af9d6837e840abdc8c".HexToBinary();
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2k);
            int rid = 500;

            string result = pek.DecryptHash(blob, rid).ToHex(true);
            string expected = "92937945B518814341DE3F726500D4FF";
            Assert.AreEqual(expected, result);
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHash_W2k_Encrypt()
        {
            // Win 2000 - Win 2012 R2
            byte[] originalHash = "92937945B518814341DE3F726500D4FF".HexToBinary();
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfb0b0f777efcece0100000000010000000000000004b7b3fd6df689af9d6837e840abdc8c".HexToBinary();
            int rid = 500;

            // Encrypt the hash and then decrypt it again
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2k);
            byte[] encryptedHash = pek.EncryptHash(originalHash, rid);
            byte[] decryptedHash = pek.DecryptHash(encryptedHash, rid);

            // Now check if we really got the original value.
            Assert.AreEqual(originalHash.ToHex(), decryptedHash.ToHex());
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHash_W2016_TestVector1()
        {
            // Win 2016 TP4+
            byte[] blob = "1300000000000000A548432796CC93BEB01E585C98F5A050100000006095B3BB2F5D39081F98B8FFAE5A8E43D66D763BD25613B44640B4E666DA5208".HexToBinary();
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfd02cd74ef843d1010000000001000000000000006a35d3fc0e9949135463ab766cac7dbb0c0c0c0c0c0c0c0c0c0c0c0ca93445b678ce5fbe02de23c3c71ff800".HexToBinary();
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2016);
            int rid = 1103;

            string result = pek.DecryptHash(blob, rid).ToHex(true);
            string expected = "92937945B518814341DE3F726500D4FF";
            Assert.AreEqual(expected, result);
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHash_LDS_W2019_Decrypt()
        {
            // Input
            byte[] bootKey = "999cd9db28620f9ccbf74aa5ab7e220c".HexToBinary();
            byte[] pekList = "0300000001000000f25b8e6b334557b94514ade0bc4c36d706b7fc0250897ce8a87f0c4edb47280303f18e4cfc4caf56fdce7eadcdae0becef361f92d7db50c69745c82604a0f52b767410638342fb66b638cd965edc90d300000000000000000000000000000000".HexToBinary();
            byte[] unicodePwd = "1300000000000000CB5C6EC9A999D969B3FBD6C28625B7E710000000A5C55D65D8FD2B884D369CA73E3DD0B8D034CD3A600DF9AC76B40F5B8862C21E".HexToBinary();
            string expectedHash = "92937945B518814341DE3F726500D4FF";

            // Decrypt
            var pek = new DataStoreSecretDecryptor(pekList, bootKey);
            string result = pek.DecryptSecret(unicodePwd).ToHex(true);
            
            // Validate
            Assert.AreEqual(expectedHash, result);
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHash_LDS_W2012_Decrypt()
        {
            // Input
            byte[] rootObjectPekList = "9BB87C8DBF9FA23A75D59E9B8F2F993C2BF966B31F097BB9FB0C9478F00F83B1F3797B8D7D35C0B5".HexToBinary();
            byte[] schemaObjectPekList = "22EEA8E5F33566076049AF604B4930108FB3FF08FDC3348F02BAB3CE84BBB045ED42D2DD580893CA".HexToBinary();
            byte[] configNCPekList = "02000000010000006124C9825F761BCAF07C2B65161CBC1B3240F1C9169BB1478CEB3B38C47FB6FC7BDB8B206DB6AD31A3DF20F35A9DEF6A49312EE7D6A4B80963A0FA2D75F3F7CB239F8E61".HexToBinary();
            byte[] unicodePwd = "1100000000000000BC0BF58E1B2238CDC5005612D1EE97E50699858A2CC8A46C1F0A47F99AB477D3".HexToBinary();
            byte[] ntPwdHistory = "1100000000000000F87413526E2F737110ACC36C7A82E7459B4C130C62D70A00C47659931A5EE26D10DD85F55AEDF165".HexToBinary();
            byte[] supplementalCredentials = "11000000000000003D51AE44B7F7450101DBD1398FF5A068F0013803B8DD11DF9E2E96731CDFDE462F14F685536104D42E4533FC00F8867419F1BFC179FFCCB2EA7FA7F152944341BB1BABD18DA0C6231B2AC68002B10A5BC2306814F5F8ADEB42BB7C13EC2C8082DF7886FBB61D86457D3F30AFB447AE69B6E96D849CE087A1E3EDF0D1C2625884C1B3E022EEF667FAE104B2E5A8752810E65260BBB60AD8D349DB1BF676760D588EE5C3A06862F2375A0B186764A1E08002A724842BE2108575836B1B752D453E8E55352EC69875BD92B77D79EE60D2C86EE5393A07E8E4F027E9F41F432134B6931685CC42FA8D5ABEAA05937342029659A52F60775EF8B042087CF8AD01567D06AEC228971D24F4D884445B972BE6AB9553E4023D22E002A3B88A117075253F24EC1750FDDAB092190B28C6CC4A3CBC52F3C1DF9AD330A7B8B87D7ED86EE01FDC5A7C5A3A9437205855FFAC40D93474E8B1D70C1F84FFC2E4FE6B6E0386DEADD5EC27EE8975FD6BD7578AB10690D11474AA147CCC603CAF2F5B7EE1A2513422D3F02DB1F51843D8079BD52CDC70B7494183DA2DFAF3ED4A3D8A4416D85900303A4208449C2D8DD483174F0E83C852FE75B54C0B4F7E2EC3AB297AAF8F4F7A78BCD88B2416F7B992E6D87C2437E971582EDD747C4FDA7A92D89BF10524327C505D910CC99EFD68A3CFDE37EB8BDECA70F7216AE51D5FC3F7B0038F315C6ECC11CA4FDA86546F78E2".HexToBinary();

            string expectedHash = "92937945B518814341DE3F726500D4FF";

            // Perform decryption
            byte[] bootKey = BootKeyRetriever.GetBootKey(rootObjectPekList, schemaObjectPekList);
            var pek = new DataStoreSecretDecryptor(configNCPekList, bootKey);
            string decryptedNTHash = pek.DecryptSecret(unicodePwd).ToHex(true);

            // Validate
            Assert.AreEqual(expectedHash, decryptedNTHash);

            throw new AssertInconclusiveException("Checks for NT history have to be added.");
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHash_W2016_TestVector2()
        {
            // Win 2016 TP4+
            byte[] blob = "1300000000000000E2FCB1CA163BAF47045BEC69E0B9747C100000002973C11ACE6228D4083ADAC2E3C98DB6C613A32C1A52016EA013CED970A1A2D4".HexToBinary();
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfd02cd74ef843d1010000000001000000000000006a35d3fc0e9949135463ab766cac7dbb0c0c0c0c0c0c0c0c0c0c0c0ca93445b678ce5fbe02de23c3c71ff800".HexToBinary();
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2016);
            int rid = 500;

            string result = pek.DecryptHash(blob, rid).ToHex(true);
            string expected = "92937945B518814341DE3F726500D4FF";
            Assert.AreEqual(expected, result);
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHash_W2016_Encrypt()
        {
            // Win 2016
            byte[] originalHash = "92937945B518814341DE3F726500D4FF".HexToBinary();
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfd02cd74ef843d1010000000001000000000000006a35d3fc0e9949135463ab766cac7dbb0c0c0c0c0c0c0c0c0c0c0c0ca93445b678ce5fbe02de23c3c71ff800".HexToBinary();
            int rid = 500;

            // Encrypt the hash and then decrypt it again
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2016);
            byte[] encryptedHash = pek.EncryptHash(originalHash, rid);
            byte[] decryptedHash = pek.DecryptHash(encryptedHash, rid);

            // Now check if we really got the original value.
            Assert.AreEqual(originalHash.ToHex(), decryptedHash.ToHex());
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHashHistory_W2k_Decrypt()
        {
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfb0b0f777efcece0100000000010000000000000004b7b3fd6df689af9d6837e840abdc8c".HexToBinary();
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2k);
            byte[] blob = "1100000000000000b9cc6e0358210d60e5f9233a47d4053ccf16b320eec132d7de81b13dace6f4e7".HexToBinary();
            int rid = 1375;
            var result = pek.DecryptHashHistory(blob, rid);
            Assert.AreEqual(1, result.Length);
            Assert.AreEqual("92937945B518814341DE3F726500D4FF", result[0].ToHex(true));
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHashHistory_LDS_W2019_Decrypt()
        {
            // Input
            byte[] rootObjectPekList = "6d94991d9c0fe72837db099c28aa12f81ea1fc285c893f51fdd9e062d8d2a3ed6eb4ac1457e1fdd3".HexToBinary();
            byte[] schemaObjectPekList = "e657f7626023770ce6a0bc7e9a1e8468c34abf61abea225824c9e100a3e789aab2814796a5cb8b07".HexToBinary();
            byte[] configNCPekList = "0300000001000000f25b8e6b334557b94514ade0bc4c36d706b7fc0250897ce8a87f0c4edb47280303f18e4cfc4caf56fdce7eadcdae0becef361f92d7db50c69745c82604a0f52b767410638342fb66b638cd965edc90d300000000000000000000000000000000".HexToBinary();
            byte[] ntPwdHistory = "130000000000000023E9D52A9EBA23C2F2A0705F58334F05400000001335D99AA6A65ACDE2E94F152D84665F2E29555606B48F5065070000972900582C5F83C01E9144434A2A00A0D27225C2590F8EEFA6ACC820EF885B0CCD4A18699AE57C7C6101FF299AFDA4CF0F92C5B0".HexToBinary();

            // Decrypt
            byte[] bootKey = BootKeyRetriever.GetBootKey(rootObjectPekList, schemaObjectPekList);
            var pek = new DataStoreSecretDecryptor(configNCPekList, bootKey);
            byte[] decryptedNTPwdHistory = pek.DecryptSecret(ntPwdHistory);

            // Validate
            throw new AssertInconclusiveException("NT hash decryption needs to be implemented.");
            // Sample: 0300000010000000e24106942bf38bcf57a6a4b29016eff6100000009d978dda95e5185bbeda9b3ae00f84b41000000092937945b518814341de3f726500d4ff
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHashHistory_W2k_Encrypt()
        {
            // Prepare the input data
            byte[] hash1 = "92937945B518814341DE3F726500D4FF".HexToBinary();
            byte[] hash2 = "31D6CFE0D16AE931B73C59D7E0C089C0".HexToBinary();
            byte[][] hashHistory = new byte[][] { hash1, hash2 };

            int rid = 500;
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfb0b0f777efcece0100000000010000000000000004b7b3fd6df689af9d6837e840abdc8c".HexToBinary();
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2k);

            // Encrypt and then decrypt the hash history
            byte[] encryptedHashHistory = pek.EncryptHashHistory(hashHistory, rid);
            byte[][] decryptedHashHistory = pek.DecryptHashHistory(encryptedHashHistory, rid);

            // Compare the result with the original data
            Assert.AreEqual(hashHistory.Length, decryptedHashHistory.Length);
            for(int i = 0; i < hashHistory.Length; i++)
            {
                CollectionAssert.AreEqual(hashHistory[i], decryptedHashHistory[i]);
            }
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreNTHashHistory_W2016_Decrypt()
        {
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfd02cd74ef843d1010000000001000000000000006a35d3fc0e9949135463ab766cac7dbb0c0c0c0c0c0c0c0c0c0c0c0ca93445b678ce5fbe02de23c3c71ff800".HexToBinary();
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2016);
            byte[] blob = "13000000000000009238F8456B0A6113E4175367351C5876F0000000C122DE3142DEA4427488F0F190B88BB36866E41784C95A1DEE8B671680F99AC88A3F0D0AC46BB296DA4DA000624773EF5976793433DD63FDAB2193AC067776AC408C6867E82267935194461BBD7957EACB35D2976465209B62022BCE029BA4C5D036A2B1AA58AC1F2D471A386D4492FC6040741AA137A542219A6F852378D539389D307403B69F97640786B34B8BD5A5246EBA9BA39854B7306B905CE84E9B42C0DDFDE1B74DF32AEDA4FCDE87CD82B3B1EA313E1D2DBD85BF89DB08EAE3641298B40101574E2AA2720E8F7C075EE3C38E20C6387767B9F89585E17379E3FC7F7BBE8D473767EAEAED57C006B477E1D8C9BA06ED2A1A0F10E77C402893B04C0D".HexToBinary();
            int rid = 1103;
            var result = pek.DecryptHashHistory(blob, rid);
            Assert.AreEqual(15, result.Length);
            Assert.AreEqual("92937945B518814341DE3F726500D4FF", result[0].ToHex(true));
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreSupplementalCredentials_W2016_Decrypt()
        {
            byte[] binaryPek = "56d98148ec91d111905a00c04fc2d4cfd02cd74ef843d1010000000001000000000000006a35d3fc0e9949135463ab766cac7dbb0c0c0c0c0c0c0c0c0c0c0c0ca93445b678ce5fbe02de23c3c71ff800".HexToBinary();
            var pek = new DataStoreSecretDecryptor(binaryPek, PekListVersion.W2016);
            byte[] blob = "13000000000000005069FBE8174A02F0873427FB1833E2B2850A0000D45F588B425E3233B92471509BE80A8611FC334C3570A5FCC9CDFE36B71E15C3C80BF99979648122A0E23C733B99B79305E2BA4C1498D4D3E504AF131ECCF97149E173566DC48786AC9126E7A408703ED727E72F870FE27F7FAD392B8DA77AB05373DABF0D65D9B8732837B6703F0CB5B160E7700C2BC06E87484348DA494FE71160B222A7D42F7567B284FFC20E043447573CEB5B896F8F600AB1484F5F6736190849F8B9ACDE10539D9A9771314155FCD95DC7EFCED13C21662B5967C0486046764E7EEC993D96090AF44DD510C0845688C3D36CA9578FEF978072E60A2DCE3F84EA09B38D3AA0571853918733900640228A505FE8A58F77CB914DA34035807D7CF7E30C2EF58A6692ADA2D986C8B7479D2B77312F1B6B1DC848EF4CD215F2D5503B0DFE24B53B0B29ED3FF4D7FB9541E4B8E3F26014405FFD84CDE063279695E9BFF28CD3AF90163FEFA0ECF26800C77CCF7DE50F0078FF01F4A4D3AA4BC5CC49DFB0DE2E33A16214B171DF8DC854A2BA32DF60143D2B9AA0BDCD7FBD0E3CA0D2859590A924380A395FA6EBB6DF0D41D76A020A7C383058D4DEC14587DAC5999E81693729F41F83EAE4CAE60979508DF56B3E17484977DE52DA4542EB2664639156DF87E89B91DFB888B9DDE6873928B9C87693FFF14982D75B1F7D6D2AF9A880C31F1EA6F71C0D650E187149E8F03DF30EF2B3B63502BC953E33F4196DA57E26DDC35B1953FE7D51347FE94171E1B4B920C3A200164171C3CE67884850766CD965CD3965DBB042DF61927211B118A741E062DBDECA5B098AAFE6AE998F5ACFBA8F2CD0CA40C4EE99CD7962491A4F7C4665F99768CD6BD4B54EDC377431E74558CA4416CA184C04807FFD2E3038E46C8BD5EF69850B1139C0CBB2B4FBEF4022A9489E33F159CCBB10461C314959ECDDF6258E9DA5B621758FC32744C6C1595A4664DF03538FB3ED3269D0B2ED603F4748726523B9D301D4FFCC294BE19E22137EFF42B0B0C5B29E416C168E91AEC61FF069D661F0A91400F16043F3A382E8B54BEB2CB2713F7A886C0C2F90AEFAE144198FF49F3137212DDAD029A6CB9AD4DF782F3D0DEA441070B3DAD7107CEE99C9255DA0A086363F4C570E88384C9876825105CB6FDA9533DEFD3E39CD11490DC8EF81592039648766351D3991FAD430B6B4A86FBAE311E1CC3A3A3526E8A39AAA63DC97AD54BF36066D8520FA83F64F7DB96710B01CA759BACF242C0FC711693CEA7A0C3B42FB60555E429DF6169D1C1E9695FDCF46E372F6FB321474B9B232DD64BCD7CD034381D7DBEC57D0E1005401345B486A6830163C68839B2351BB2AF9FB7430C66DA3C7B921D3CF4368D5490D54571A868F4FAB058768F1A0885D2D94D4CCD1E5DD2B773591D88B2A3047EB6D63C624C215C1DCA5F82358E2300DEB6BF7A284A0CEEF1B82296200E0CE922662CAB1F546E455A4C52F7F0ABE0033E7BFAE4DA3BFE67C3D456CCD2687BC9DDA419723B2A4071C65660483B5787C42599AB6D8E05523F711C1F73D1BA4EE6F4255CE53DD739F3F11D737740CAF3F4DC01615E9D1389C79748FE1DF2EAC833B31456AD236EE1D2D5399E9826C93872A6C8BDAD3D6205C592EC73D2A8B463A0C5AD7DFC07AB8395AD76620E76131D8254233E7ED3858392AC86C2057AFCC1426891D1EC94B9C9F338629C8F58B05F6A26BC7D3D472D33F5020B0FE160F674EAF95EEE9FF59FE7129C07AB0F551DF16A675B32B0487EE08402A9E541EEF6B5FADCB96EDEA51C3AAB392A534DD95F98E94F6B0EDBDFF12D49B936DDD1B092836147D5420709EC00819AE4C97A8C464CABB0C958CFC3199A5C2AC2BC51E82316B568ED4FCACC2518E6F837878AA9022337D4989A061674801887278EB2BC38007D9EE1E9745E841B96E48D04BDAD51612513EB196FED7A6442D73728FD6AC3A7106E16F75823668AEC2A22BC24A8D40B620DC37952B8D2B358749AAA26BB304B1F0D46AF6C370C5B89D0CC817BFAB5CD73F5E117BFB22C39ED012EFF05E5CDC87D67227B4285E10D5475AFA3A387DA9AAD12FB968DC35D091A918C6C33B6850565DEDB3C2172D3CCEE9002AB7F04AD1172AE2E92B1DD9561385E17B360A66D5ED1E47B125EA497A5BBDC63D99493E03043DE36CAEBDBDF8CE10A0635CBF1955088B59FAD69A8ECF0C4A5707E02CA00239C6B1C7AD5F574FE073A10976D3703622220E61ED0A134EB0754AE1F56FE9474153260CB97C2E29E8D58D7E6BC76643F8C46BDD434E408A64AF06906B99648DA98CD0021C2D1095ED10A70C691ADBCC4FD5CBE8AE7C5A2B39FE75F468CB948EE9EAFA2149B34C27367559301D51CFBD957F80F0BA4CC6BFA10D7A2961002359FF1EC477B35225BA5B5C81B391C145B55261A9F3BA2F989433FDEE3D6007F6571F2EB48875014904743F01AFB810F68A5C307112EA2CC538D74C2AA16710EA74F36864A76D943803AE3826577F5EEB5A9A5A76F500382B56A8C78445B51C0E375403A7E46235E5143C1B82C1118BEE6E0D6886204C1F70611EDF88077E2E1D686635FA4670150A6871A205CCBC258A3148E4D95E01E17AFFEA84147555237D499A6D0BFB18F501A8A84589DCE60BAF6026D373D531D5908ADB9AC51F90EACBE3276B2B55B61DDB0AA89869A28C72265593B135C62969DEFF3ABF8223A5BF262E555EEC842534C9DC0C48344FE087B4327F7E5668C5C722D8384B75DC00A82F490ED70779990E634A04C45306F76F875BD75BE87C620830A16CCD49A3906C5F7096FA78F7652E452A5F738DA7F76A5447936B9144135B39727D89FDD49E3777D848B0A1FA0500CE48FB5E85A50A2B4482A7C54AFE92EB59626D5206EAA486E5D39FF2E46054647AED72DA4FD41F63E7AEF2FC0B2C1041A2BBA7F47EFAE8E36AB4DA1F11393C59102455270DD622E500B39657194A05FFC8F4EE0664AA178D52608C7947FD0AD704B3615C2FFD1861FB484B8A3DFAE884315F4AB3716D6B2230C6E2003420B5A8D5E813098CED354E27BF41BDDE67BE6F3AE314EB0A324B229C5EAD1A5E65D9B0164312F19D06A94721AE589D6D80A4FCFEFA62D388E8673A2CB29D9177F8BDB5C1D3F277FEA954161244DB89B3B7026E0279DF92230A69C34C4662DCFD777CF1FF4CF3F8DE7A5B591FD72191EBE91B65E778F2FAF1C734BA55C5905D511066EB5B5784CC62738C787FC0A62FFE18E758D0FCC61FAE32BD12C8B5C8BA97C555D8649A9179C8D010F0E3E0855C6F7B14433FA637BD5563488EA8A39F0F5CB28B7428EFE8F15D3AC05D25E71D54B89E04B1DF6F3D458A141AF116EC951CBBE2A7DCE480499DE172A4D999E3512CD22E95DF314B53EBFF166714DE65F56A7929BBAB952F38421AA0BAF15319BCA77AB1410DC5CF8776911D2CD227363182FFF95772498A33FD2695DF05FBE83BCCB15A8BC0F3D667BA30BA1999A0538D8E680C7637764CEBAC51E933302A530F91D83A33A88F92363D6008732B0CFFBE2B7244ACDB1A4CAE551FB80D8B720CE5AFA51374A51296C4FB6517E002FB90382F26DF8B5144D02C3BA97DFF823C6112B7EF7E35878714318A88C966C7F225E71AA0CEB2465D839CBBB86382672F8197A45B82E8EDACD0C021899BF1F832C9FD2DCFE772C8AC9B81F5C95D57CCC1D47D3B62015174BD3F4DB152A8EE1967FE3EED65BE10E86FE751A5E1FFA2B378897F9AE347CD0E6C1D5A090F88EBF8A972742827B80832B5F2808E62BEB7C56933A63B321474E64384DE793E58A91D27A149C5A80F2C3423736D27A5445E0BED3E71C3174FF1BBF2BCF85A2170EF4C323B1F77E5".HexToBinary();
            var decryptedBlob = pek.DecryptSecret(blob);
            var cred = new SupplementalCredentials(decryptedBlob);

            // Check properties
            Assert.AreEqual("90545eb4cae416368f019e59e77e8551", cred.NTLMStrongHash.ToHex());
            Assert.AreEqual(29, cred.WDigest.Length);
            Assert.AreEqual(1, cred.Kerberos.Credentials.Length);
            Assert.AreEqual(3, cred.KerberosNew.Credentials.Length);
            Assert.AreEqual(4096, cred.KerberosNew.DefaultIterationCount);
        }

        [TestMethod]
        public void PasswordEncryptionKey_DataStoreSupplementalCredentials_LDS2016_Decrypt()
        {
            // Input
            byte[] rootObjectPekList = "D3433ED00F5CBA529A2CC7CC53403803F331B0CEA913E8DE16A87379BC27635363A52C79CA54D5B0".HexToBinary();
            byte[] schemaObjectPekList = "0A1B334917DC2815D149D2BE5C3D653C22DC91FB03608E4AE0F5EA79CCD098D989C2146BFF7BD66D".HexToBinary();
            byte[] configNCPekList = "0300000001000000A0F0A0BB2BF94ED078F440941FEEF85C586E776F6D292254DEDC31DF47DC3026D3D7F7C6AB80FDB24D54CF50C89B3185892E85C70DEC9B3A89690938E827F4442C674AC548524CBEE75A881CBBD23ACB00000000000000000000000000000000".HexToBinary();
            byte[] supplementalCredentials = "13000000000000009D99B54F6E92238AB0C53044C28725F7F8010000631BDFB8CAA411E58A6CFCB760165A2B0733DE6E4FDC288DB7262B8AF416EF1A6F2206BF7224FD6DF021DF0FC4A9E1693AA5161B02ED433D7DD8A265BE6A647CB79D4D6E0C79C9BD282B2FC7F33F47405A97909EC02E3A879216DF613EA88678D72199B31887484AAF2FBFC2275A0B90B1B24B03222867EBB8AF8DC2C490C799B0ED1C65B11E5487E48ACC4B684C60EFF8219596C7D91042DCB7DC27450E23891676EFB5F4A2FF930358625665331893854E7F19B41E01E5FEC24A895625990BD05CDF53D5B6940888819FE74B0F3364AC117A72758C191B9F94D213EA87206E4E0F5D88B778DEF1B2D3B501F12D441DD35415F71B4768F1D9B79A3D3769CEB215CE672E318FEEBE67C6888A868DDEAD665F509EEFA3826D7ED3C08FB2F10B1744821FB3F0F63DBB514337857C5D1106CC05E33B9D4B55F2492CE68F3F73B7DF52E86763DB0C183F9976EA8339B3791EA3A0598B0C02980B397955B76233FCB2ECDFCC3D6AB8EE559B7B90C21904A5736C72598EE79F1551BC6862EB24154CC4E3E2732486C6AF1746361D2D59EF0F55E16E03EEDAD26E3C60E910D1D0B835C73818BC5C187666BE269DFC85A1E8D2CB1BF5F0871AB740FB203E4CE4F92D339EAE2706D1AA82FBE27648A95CEA342E8C758CCCDA82DEEDF5336940C4BF001339DC517BD5B7B5F115DDF76F2CFD0E6E836499AC6C779F8F5F8784EF6BB343315F".HexToBinary();
            // User: CN=john,DC=dsinternals,DC=com, SID: S-1-368974073-1255603998-1555295481-1167413779-2898941572-359884799, Password: Pa$$w0rd

            // Decrypt
            byte[] bootKey = BootKeyRetriever.GetBootKey(rootObjectPekList, schemaObjectPekList);
            var pek = new DataStoreSecretDecryptor(configNCPekList, bootKey);
            byte[] decryptedSupplementalCredentials = pek.DecryptSecret(supplementalCredentials);

            throw new AssertInconclusiveException("Supplemental credentials decryption needs to be implemented.");
            // Sample: 0100000001000000e80100000600000001000000e00100003100011d000000000000000000000000af4156909297baece4e553b731d9d552da58c12e5880cad54a3f909c07b0792eec9d262783c811ad9cc7aeb1ab019fe0af4156909297baece4e553b731d9d552af4156909297baece4e553b731d9d552ec9d262783c811ad9cc7aeb1ab019fe0da58c12e5880cad54a3f909c07b0792e95e11e920c7405ca6639d932888cc11c53d9e953141b322f29eb1a02798c299042eea90067734b2a81abbc79618cc1519d9aac28e63107a495266e755f7a2babac6b5dfb3bfa3b7039058310d5b36ccc7c97824dd59b9a6a053b5fae3d8603f20a5e2bc3111c759efb3a91e3740633e83b12daad09e83cb92477ac59993c5a843b12daad09e83cb92477ac59993c5a843b12daad09e83cb92477ac59993c5a8471e7228faba51df979beef06b34f791820aa1475f40540f0db59f9d2d93fc3da5f88f6d82d185741a82c7fa79e801c6d8eae592a0ce55271a17de0b39cf1e5e9923354fb99887724cf2b10e88108776b427804b8a6d6ed92c11ecb94e40da72c0c997bc1906b1f0092d61bd0efee428b0c997bc1906b1f0092d61bd0efee428b0c997bc1906b1f0092d61bd0efee428bd93e9a9a7452dff036a67a5d5d333d7c4effe21b0afc142382943ef26024649aaa6a6a95c237f2b8efa2f13ecb0cb220
        }
    }
}