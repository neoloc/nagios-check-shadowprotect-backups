# Check eventlog for shadowprotect errors or warnings
#
# This script will look at the application log for eventid 1121 and 1122, if any
# are found then the appropriate warn/crit message is returned to NAGIOS for
# further investigation.
#
# If no backups failures or aborts are found, and no successes are found then
# a warning or critical message will also be sent.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Originally created by Ben Vincent (ben.vincent@oneitservices.com.au)
#
# Resources:
#     https://www.storagecraft.com/support/kb/article/123
#

# nagios specific stuff
$NagiosStatus = "0"
$NagiosDescription = ""
$NagiosWarn_Hours = "48"
$NagiosCrit_Hours = "24"

# check if if using Shadowprotect or ShadowprotectSPX
If (get-service -name ShadowProtectSVC -ErrorAction SilentlyContinue){
  # check if the host is Windows 2008r2/7 (Windows 6.1) or newer
  If ([Environment]::OSVersion.Version -ge (new-object 'Version' 6,1))
  {
    # get the event data for the local machine
    $FailEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=1121; providername='ShadowProtectSVC'} -MaxEvents 10 -ErrorAction SilentlyContinue
    $AbortEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=1122; providername='ShadowProtectSVC'} -MaxEvents 10 -ErrorAction SilentlyContinue
    $SuccessEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=1120; providername='ShadowProtectSVC'} -MaxEvents 10 -ErrorAction SilentlyContinue
  }
  else
  {
    # get the event data for the local machine. This is a slower method so change the maxevents to suit your environment.
    $FailEvents = Get-WinEvent -LogName Application -MaxEvents 2000 | Where-Object{($_.ID -eq "1122") -and ($_.ProviderName -eq "ShadowProtectSVC")}
    $AbortEvents = Get-WinEvent -LogName Application -MaxEvents 2000 | Where-Object{($_.ID -eq "1121") -and ($_.ProviderName -eq "ShadowProtectSVC")}
    $SuccessEvents = Get-WinEvent -LogName Application -MaxEvents 2000 | Where-Object{($_.ID -eq "1120") -and ($_.ProviderName -eq "ShadowProtectSVC")}
  }
}elseif (get-service -name SPXService -ErrorAction SilentlyContinue){
  # check if the host is Windows 2008r2/7 (Windows 6.1) or newer
  If ([Environment]::OSVersion.Version -ge (new-object 'Version' 6,1))
  {
    # get the event data for the local machine
    $FailEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=5; providername='ShadowProtectSPX'} -MaxEvents 10 -ErrorAction SilentlyContinue
    $AbortEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=4; providername='ShadowProtectSPX'} -MaxEvents 10 -ErrorAction SilentlyContinue
    $SuccessEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=3; providername='ShadowProtectSPX'} -MaxEvents 10 -ErrorAction SilentlyContinue
  }
  else
  {
    # get the event data for the local machine. This is a slower method so change the maxevents to suit your environment.
    $FailEvents = Get-WinEvent -LogName Application -MaxEvents 2000 | Where-Object{($_.ID -eq "5") -and ($_.ProviderName -eq "ShadowProtectSVC")}
    $AbortEvents = Get-WinEvent -LogName Application -MaxEvents 2000 | Where-Object{($_.ID -eq "4") -and ($_.ProviderName -eq "ShadowProtectSVC")}
    $SuccessEvents = Get-WinEvent -LogName Application -MaxEvents 2000 | Where-Object{($_.ID -eq "3") -and ($_.ProviderName -eq "ShadowProtectSVC")}
  }
}else{
  # Shadowprotect and ShadowProtectSPX are not installed. Exit as warning.
  Write-Host "WARNING: Shadowprotect not installed"
  exit 1
}

# FAILED BACKUPS
# check for critical alerts (failed within last $NagiosCrit_Hours hours)
Foreach ($event in $FailEvents)
{
  If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Shadowprotect has failed backups in the last " + $NagiosCrit_Hours + " hours"

    # Set the status to critical.
    $NagiosStatus = "2"

    # Output the nagios error text and then exit
    Write-Host "CRITICAL: " $NagiosDescription
    exit $NagiosStatus
  }
}

# check for warnings alerts (failed within last $NagiosWarn_Hours hours)
Foreach ($event in $FailEvents)
{
  If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Shadowprotect has failed backups in the last " + $NagiosWarn_Hours + " hours"

    # Set the status to critical.
    $NagiosStatus = "1"

    # Output the nagios error text and then exit
    Write-Host "WARNING: " $NagiosDescription
    exit $NagiosStatus
  }
}

# ABORTED BACKUPS
# check for critical alerts (aborted within last $NagiosCrit_Hours hours)
Foreach ($event in $AbortEvents)
{
  If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Shadowprotect has aborted backups in the last " + $NagiosCrit_Hours + " hours"

    # Set the status to critical.
    $NagiosStatus = "2"

    # Output the nagios error text and then exit
    Write-Host "CRITICAL: " $NagiosDescription
    exit $NagiosStatus
  }
}

# check for warnings alerts (failed within last $NagiosWarn_Hours hours)
Foreach ($event in $AbortEvents)
{
  If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Shadowprotect has aborted backups in the last " + $NagiosWarn_Hours + " hours"

    # Set the status to critical.
    $NagiosStatus = "1"

    # Output the nagios error text and then exit
    Write-Host "WARNING: " $NagiosDescription
    exit $NagiosStatus
  }
}

# SUCCESSFUL BACKUPS
# check for successful backups within the last $NagiosCrit_Hours hours, report OK
Foreach ($event in $SuccessEvents)
{
  If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Shadowprotect has successful backups in the last " + $NagiosCrit_Hours + " hours"

    # Set the status to successful.
    $NagiosStatus = "0"

    # Output the nagios error text and then exit
    Write-Host "OK: " $NagiosDescription
    exit $NagiosStatus

  }
}

# check for successful backups within the last $NagiosWARN_Hours hours, report WARN
Foreach ($event in $SuccessEvents)
{
  If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Shadowprotect has successful backups in the last " + $NagiosWarn_Hours + " hours but not " + $NagiosCrit_Hours + " hours."

    # Set the status to warning.
    $NagiosStatus = "1"

    # Output the nagios error text and then exit
    Write-Host "WARNING: " $NagiosDescription
    exit $NagiosStatus

  }
}

# else if no failures, aborts or successes. Are backups even running?
If ($NagiosStatus -eq "0")
{
  # Set the nagios alert description
  $NagiosDescription = "Shadowprotect has has no backup reports in the last " + $NagiosWarn_Hours + " hours"

  # Set the status to critical.
  $NagiosStatus = "2"

  # Output the nagios error text and then exit
  Write-Host "CRITICAL: " $NagiosDescription
  exit $NagiosStatus
}


# if you get to here, something went wrong. Report to nagios so we can debug.
Write-Host "UNKNOWN: Failed to check backup status"
exit 3
