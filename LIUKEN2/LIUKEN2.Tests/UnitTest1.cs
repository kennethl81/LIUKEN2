using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Net;
using System.IO;
using System.Security.AccessControl;

namespace LIUKEN2.Tests
{
    [TestClass]
    public class UnitTest1
    {
        /// <summary>
        /// Test to see if we can make a HTTP request
        /// </summary>
        [TestMethod]
        public void checkConnection()
        {
            //Arrange
            var request = (HttpWebRequest)WebRequest.CreateHttp("http://www.goodreads.com");
            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            {

            }

            //Act
            var getHTTPConnection = request.Connection;

            //Assert
            Assert.IsNotNull(getHTTPConnection);
        }

        //check if logged in
       [TestMethod]
       public void checkIfLoggedIn()
        {

        }

        [TestMethod]
        public void checkQuoteCount()
        {
            GoodReads goodRead = new GoodReads();
            int testSize = 10;

            goodRead.quoteCount = testSize;

            Assert.AreEqual(goodRead.quoteCount, testSize);
        }

        //test whether file can be written to file system (directory exists)
        [TestMethod]
        public void checkFileSystemForDirectoryExistsAndWriteAccess()
        {
            FileHandler fileHandler = new FileHandler();
            string directory = "C:\\";
           // DirectorySecurity directorySecurity = new DirectorySecurity();

           // bool checkWriteAccess = directorySecurity.AccessRightType.Equals("Write");

            bool checkFileHandler = fileHandler.hasWriteDirectory(directory);
            bool checkDirectoryExists = Directory.Exists(directory);

            Assert.AreEqual(checkFileHandler, checkDirectoryExists);
        }
    }
}
