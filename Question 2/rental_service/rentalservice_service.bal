import ballerina/grpc;

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: RENTAL_DESC}
service "RentalService" on ep {

    remote function AddProperty(AddPropertyRequest value)
            returns AddPropertyResponse|error {
        return addProperty(value);
    }

    remote function UpdateProperty(UpdatePropertyRequest value)
            returns UpdatePropertyResponse|error {
        return updateProperty(value);
    }

    remote function RemoveProperty(RemovePropertyRequest value)
            returns RemovePropertyResponse|error {
        return removeProperty(value);
    }

    remote function SearchProperty(SearchPropertyRequest value)
            returns SearchPropertyResponse|error {
        return searchProperty(value);
    }

    remote function BookProperty(BookPropertyRequest value)
            returns BookPropertyResponse|error {
        return bookProperty(value);
    }

    remote function ConfirmBooking(ConfirmBookingRequest value)
            returns ConfirmBookingResponse|error {
        return confirmBooking(value);
    }

    remote function CreateUsers(stream<User, grpc:Error?> clientStream)
            returns CreateUsersResponse|error {
        int created = 0;
        string[] failures = [];

        error? streamErr = from User u in clientStream
            do {
                UserRecord|ServiceError result = registerUser(u);
                if result is UserRecord {
                    created += 1;
                } else {
                    failures.push(result.message);
                }
            };

        if streamErr is error {
            return {
                created_count: created,
                message: string `Stream error: ${streamErr.message()}`
            };
        }

        string summary = failures.length() == 0
            ? string `Registered ${created} user(s).`
            : string `Registered ${created} user(s). ${failures.length()} failed: ${failures.toString()}`;
        return {created_count: created, message: summary};
    }

    remote function ListAvailableProperties(ListAvailableRequest value)
            returns stream<Property, error?>|error {
        PropertyRecord[] matches = collectAvailable(value);
        Property[] out = [];
        foreach PropertyRecord p in matches {
            out.push(toProtoProperty(p));
        }
        return out.toStream();
    }
}