import ballerina/time;

table<Asset> key(assetTag) assetsTable = table [];
map<Institution> institutions = {};


function todayIso() returns string {
    time:Utc now = time:utcNow();
    time:Civil civil = time:utcToCivil(now);
    string mm = civil.month < 10 ? string `0${civil.month}` : civil.month.toString();
    string dd = civil.day < 10 ? string `0${civil.day}` : civil.day.toString();
    return string `${civil.year}-${mm}-${dd}`;
}

function isScheduleOverdue(Schedule s) returns boolean {
    if s.status != "PENDING" {
        return false;
    }
    return s.dueDate < todayIso();
}

function assetHasOverdueSchedule(Asset a) returns boolean {
    foreach Schedule s in a.schedules {
        if isScheduleOverdue(s) {
            return true;
        }
    }
    return false;
}

int sequenceCounter = 0;

function nextId(string prefix) returns string {
    sequenceCounter += 1;
    time:Utc now = time:utcNow();
    int ticks = <int>now[0];
    return string `${prefix}-${ticks}${sequenceCounter}`;
}
