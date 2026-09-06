function init() {

    institutions["Namibia University of Science and Technology"] = {
        name: "Namibia University of Science and Technology",
        sites: ["Main Campus - Innovation Lab", "Main Campus - Library", "Faculty of Computing"]
    };

    institutions["University of Namibia"] = {
        name: "University of Namibia",
        sites: ["Main Campus - Computer Lab 2", "Khomasdal Campus"]
    };

    assetsTable.add({
        assetTag: "NUST-LIB-3DP-001",
        name: "Pro-Series 3D Printer",
        description: "High-precision laboratory printer for simulation and prototype development.",
        institution: "Namibia University of Science and Technology",
        site: "Main Campus - Innovation Lab",
        status: "AVAILABLE",
        dateAcquired: "2024-03-10",
        components: [
            {compId: "C101", name: "High-Torque Stepper Motor", description: "Main motor for X-axis movement."}
        ],
        schedules: [
            {scheduleId: "SCH-882", 'type: "MAINTENANCE", dueDate: "2026-09-01", description: "Quarterly calibration and nozzle cleaning.", status: "PENDING"}
        ],
        workOrders: [
            {
                orderId: "WO-554",
                status: "OPEN",
                description: "Nozzle heat-bed failure",
                tasks: [{taskId: "T1", description: "Check thermal sensor connectivity.", completed: false}]
            }
        ]
    });

    assetsTable.add({
        assetTag: "NUST-LIB-BK-045",
        name: "Introduction to Distributed Systems",
        description: "Core textbook, 4th edition.",
        institution: "Namibia University of Science and Technology",
        site: "Main Campus - Library",
        status: "AVAILABLE",
        dateAcquired: "2023-01-15",
        components: [],
        schedules: [],
        workOrders: []
    });

    assetsTable.add({
        assetTag: "UNAM-LAB-LP-012",
        name: "Dell Latitude 5440",
        description: "Loan laptop for postgraduate research.",
        institution: "University of Namibia",
        site: "Main Campus - Computer Lab 2",
        status: "LOANED_OUT",
        dateAcquired: "2025-02-20",
        components: [],
        schedules: [
            {scheduleId: "LN-001", 'type: "LOAN", dueDate: "2026-08-05", description: "Loaned to J. Amutenya", status: "PENDING"}
        ],
        workOrders: []
    });

    assetsTable.add({
        assetTag: "NUST-FAC-MR-007",
        name: "Faculty of Computing Meeting Room",
        description: "8-seat meeting room with projector.",
        institution: "Namibia University of Science and Technology",
        site: "Faculty of Computing",
        status: "AVAILABLE",
        dateAcquired: "2022-11-01",
        components: [],
        schedules: [],
        workOrders: []
    });

    assetsTable.add({
        assetTag: "UNAM-LAB-PC-030",
        name: "HP EliteDesk Thin Client",
        description: "Thin client, computer lab row 3.",
        institution: "University of Namibia",
        site: "Main Campus - Computer Lab 2",
        status: "UNDER_MAINTENANCE",
        dateAcquired: "2021-06-12",
        components: [],
        schedules: [
            {scheduleId: "SCH-100", 'type: "MAINTENANCE", dueDate: "2026-06-01", description: "Replace failing power supply.", status: "PENDING"}
        ],
        workOrders: [
            {
                orderId: "WO-200",
                status: "OPEN",
                description: "Does not power on reliably",
                tasks: [{taskId: "T1", description: "Test PSU voltage output.", completed: false}]
            }
        ]
    });
}
