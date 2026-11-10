namespace Ogma.Windows;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        using var mutex = new Mutex(true, @"Local\Ogma.Windows", out var firstInstance);
        if (!firstInstance)
        {
            MessageBox.Show("Ogma is already running. Open Settings from its notification area icon.", "Ogma");
            return;
        }
        ApplicationConfiguration.Initialize();
        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
        Application.ThreadException += (_, e) => MessageBox.Show(e.Exception.Message, "Ogma encountered a problem", MessageBoxButtons.OK, MessageBoxIcon.Error);
        try
        {
            using var app = new TrayApplication();
            Application.Run(app);
        }
        catch (Exception e)
        {
            MessageBox.Show(e.Message, "Ogma could not start", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
