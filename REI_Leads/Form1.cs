using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace REI_Leads
{
    public partial class appLanding : Form
    {
        public appLanding()
        {
            InitializeComponent();
        }

        private void btnGo_Click(object sender, EventArgs e)
        {
            this.Visible = false;     // this = is the current form
            appMain main = new appMain();  //appMain is the name of  my other form
            main.Visible = true;
        }

        private void lblHelloWorld_Click(object sender, EventArgs e)
        {

        }
    }
}
