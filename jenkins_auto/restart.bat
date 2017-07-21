schtasks /end /tn JenkinsSlave
sc stop schedule
sc start schedule
schtasks /run /tn JenkinsSlave


