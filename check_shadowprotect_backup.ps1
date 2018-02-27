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

# get the event data for the local machine
$FailEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=1121} -MaxEvents 10
$AbortEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=1122} -MaxEvents 10
$SuccessEvents = Get-WinEvent -FilterHashtable @{logname="application"; id=1122} -MaxEvents 10

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
    $NagiosDescription = "Shadowprotect has successful backups in the last " + $NagiosWarn_Hours + " hours"

    # Set the status to warning.
    $NagiosStatus = "1"

    # Output the nagios error text and then exit
    Write-Host "WARNING: " $NagiosDescription
    exit $NagiosStatus

  }
}

# else if no failures, aborts or successes. Are backups even running?
If ($NagiosStatus == "0")
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