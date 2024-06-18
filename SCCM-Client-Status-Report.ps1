# Script written by Saeid Esmaili on 01-03-2023
# Define SCCM server and database details
$SCCMServer = "********" # SCCM-server
$SCCMDB = "**********" # SCCM-database

# Define SQL query to retrieve client information with corrected column names
$query = @"
SELECT Name0 AS Name, Last_Logon_Timestamp0 AS LastLogonTimestamp, Client0 AS Client, Client_Type0 AS ClientType
FROM v_R_System
WHERE Client0 = 1
"@

# Define the connection string
$connString = "Server=$SCCMServer;Database=$SCCMDB;Integrated Security=True;"

# Function to log messages with a timestamp
function Log-Message {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp][$type] $message"
}

# Execute the query within a try-catch block for error handling
try {
    Log-Message "Starting script execution."

    # Step 1: Create a SQL connection
    Log-Message "Creating SQL connection."
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connString
    
    # Open the SQL connection
    $conn.Open()
    Log-Message "Successfully connected to the database."

    # Step 2: Create a SQL command
    Log-Message "Creating SQL command."
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $query
    Log-Message "SQL command created: $query"

    # Step 3: Execute the command and load the results into a dataset
    Log-Message "Executing SQL command."
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset)
    Log-Message "Query executed and data retrieved."

    # Close the SQL connection
    $conn.Close()
    Log-Message "Database connection closed."

    # Step 4: Get the results from the dataset
    $clients = $dataset.Tables[0]
    Log-Message "Number of clients retrieved: $($clients.Rows.Count)"

    # Check if clients were retrieved successfully
    if ($clients.Rows.Count -eq 0) {
        Log-Message "No clients were retrieved. Ensure you have permissions and there are devices in the SCCM database." "ERROR"
        return
    }

    # Validate retrieved data
    Log-Message "Validating retrieved data."
    if ($clients.Columns["Name"] -eq $null -or $clients.Columns["LastLogonTimestamp"] -eq $null -or $clients.Columns["Client"] -eq $null -or $clients.Columns["ClientType"] -eq $null) {
        Log-Message "Required columns are missing from the retrieved data." "ERROR"
        return
    }

    # Step 5: Export the results to a CSV file
    $csvPath = "C:\SCCMClientStatus.csv"
    Log-Message "Exporting data to CSV file at $csvPath."
    $clients | Export-Csv -Path $csvPath -NoTypeInformation
    Log-Message "Client status report generated at $csvPath"

    Log-Message "Script execution completed successfully."
} catch {
    # Error handling
    Log-Message "An error occurred: $_" "ERROR"
}
