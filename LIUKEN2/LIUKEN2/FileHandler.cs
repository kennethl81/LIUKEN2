using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace LIUKEN2
{
    public class FileHandler : IFileHandler
    {
        public bool hasWriteDirectory(string path)
        {
            return Directory.Exists(path);
        }
    }
}
