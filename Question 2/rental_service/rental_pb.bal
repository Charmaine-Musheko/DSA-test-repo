import ballerina/grpc;
import ballerina/protobuf;

public const string RENTAL_DESC = "0A0C72656E74616C2E70726F746F120672656E74616C22AB020A0850726F7065727479121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A07686F73745F69641802200128095206686F7374496412120A046E616D6518032001280952046E616D65121A0A086C6F636174696F6E18042001280952086C6F636174696F6E12160A06726567696F6E1805200128095206726567696F6E12230A0D70726F70657274795F74797065180620012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180720012801520D70726963655065724E69676874122E0A0673746174757318082001280E32162E72656E74616C2E50726F7065727479537461747573520673746174757312200A0B6465736372697074696F6E180920012809520B6465736372697074696F6E2287010A045573657212170A07757365725F6964180120012809520675736572496412120A046E616D6518022001280952046E616D6512140A05656D61696C1803200128095205656D61696C12240A04726F6C6518042001280E32102E72656E74616C2E55736572526F6C655204726F6C6512160A06726567696F6E1805200128095206726567696F6E22430A094461746552616E676512190A08636865636B5F696E1801200128095207636865636B496E121B0A09636865636B5F6F75741802200128095208636865636B4F757422C4010A07426F6F6B696E67121D0A0A626F6F6B696E675F69641801200128095209626F6F6B696E674964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496412190A0867756573745F696418032001280952076775657374496412270A05646174657318042001280B32112E72656E74616C2E4461746552616E676552056461746573121D0A0A746F74616C5F636F73741805200128015209746F74616C436F737412160A06737461747573180620012809520673746174757322720A0E52656D6F766564426F6F6B696E6712290A07626F6F6B696E6718012001280B320F2E72656E74616C2E426F6F6B696E675207626F6F6B696E6712160A06726561736F6E1802200128095206726561736F6E121D0A0A72656D6F7665645F6174180320012809520972656D6F766564417422E4010A1241646450726F70657274795265717565737412170A07686F73745F69641801200128095206686F7374496412120A046E616D6518022001280952046E616D65121A0A086C6F636174696F6E18032001280952086C6F636174696F6E12160A06726567696F6E1804200128095206726567696F6E12230A0D70726F70657274795F74797065180520012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180620012801520D70726963655065724E6967687412200A0B6465736372697074696F6E180720012809520B6465736372697074696F6E226A0A1341646450726F7065727479526573706F6E7365121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412180A077375636365737318022001280852077375636365737312180A076D65737361676518032001280952076D65737361676522F0010A1555706461746550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F70657274794964122B0A0F70726963655F7065725F6E696768741802200128014800520D70726963655065724E6967687488010112330A0673746174757318032001280E32162E72656E74616C2E50726F70657274795374617475734801520673746174757388010112250A0B6465736372697074696F6E1804200128094802520B6465736372697074696F6E88010142120A105F70726963655F7065725F6E6967687442090A075F737461747573420E0A0C5F6465736372697074696F6E227A0A1655706461746550726F7065727479526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D657373616765122C0A0870726F706572747918032001280B32102E72656E74616C2E50726F7065727479520870726F706572747922380A1552656D6F766550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F706572747949642291010A1652656D6F766550726F7065727479526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D65737361676512430A1472656D61696E696E675F70726F7065727469657318032003280B32102E72656E74616C2E50726F7065727479521372656D61696E696E6750726F7065727469657322790A144C697374417661696C61626C655265717565737412270A0F6C6F636174696F6E5F66696C746572180120012809520E6C6F636174696F6E46696C746572121B0A096D696E5F707269636518022001280152086D696E5072696365121B0A096D61785F707269636518032001280152086D6178507269636522380A1553656172636850726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F70657274794964227E0A1653656172636850726F7065727479526573706F6E7365121C0A09617661696C61626C651801200128085209617661696C61626C6512180A076D65737361676518022001280952076D657373616765122C0A0870726F706572747918032001280B32102E72656E74616C2E50726F7065727479520870726F70657274792287010A134372656174655573657273526573706F6E736512230A0D637265617465645F636F756E74180120012805520C63726561746564436F756E7412180A076D65737361676518022001280952076D65737361676512310A0D637265617465645F757365727318032003280B320C2E72656E74616C2E55736572520C63726561746564557365727322450A104C69737455736572735265717565737412310A0B726F6C655F66696C74657218012001280E32102E72656E74616C2E55736572526F6C65520A726F6C6546696C746572222C0A11536561726368557365725265717565737412170A07757365725F6964180120012809520675736572496422660A1253656172636855736572526573706F6E736512140A05666F756E641801200128085205666F756E6412180A076D65737361676518022001280952076D65737361676512200A047573657218032001280B320C2E72656E74616C2E55736572520475736572227A0A13426F6F6B50726F70657274795265717565737412190A0867756573745F6964180120012809520767756573744964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496412270A05646174657318032001280B32112E72656E74616C2E4461746552616E676552056461746573228A010A14426F6F6B50726F7065727479526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D65737361676512170A07636172745F6964180320012809520663617274496412250A0E657374696D617465645F636F7374180420012801520D657374696D61746564436F7374224B0A15436F6E6669726D426F6F6B696E675265717565737412190A0867756573745F696418012001280952076775657374496412170A07636172745F6964180220012809520663617274496422770A16436F6E6669726D426F6F6B696E67526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D65737361676512290A07626F6F6B696E6718032001280B320F2E72656E74616C2E426F6F6B696E675207626F6F6B696E6722510A134C697374426F6F6B696E67735265717565737412190A0867756573745F6964180120012809520767756573744964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496422350A14536561726368426F6F6B696E6752657175657374121D0A0A626F6F6B696E675F69641801200128095209626F6F6B696E67496422CD010A15536561726368426F6F6B696E67526573706F6E736512140A05666F756E641801200128085205666F756E6412180A0772656D6F766564180220012808520772656D6F76656412180A076D65737361676518032001280952076D65737361676512290A07626F6F6B696E6718042001280B320F2E72656E74616C2E426F6F6B696E675207626F6F6B696E67123F0A0F72656D6F7665645F626F6F6B696E6718052001280B32162E72656E74616C2E52656D6F766564426F6F6B696E67520E72656D6F766564426F6F6B696E67224D0A1452656D6F7665426F6F6B696E6752657175657374121D0A0A626F6F6B696E675F69641801200128095209626F6F6B696E67496412160A06726561736F6E1802200128095206726561736F6E228C010A1552656D6F7665426F6F6B696E67526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D657373616765123F0A0F72656D6F7665645F626F6F6B696E6718032001280B32162E72656E74616C2E52656D6F766564426F6F6B696E67520E72656D6F766564426F6F6B696E6722580A1A4C69737452656D6F766564426F6F6B696E67735265717565737412190A0867756573745F6964180120012809520767756573744964121F0A0B70726F70657274795F6964180220012809520A70726F706572747949642A710A0E50726F7065727479537461747573121F0A1B50524F50455254595F5354415455535F554E5350454349464945441000120D0A09415641494C41424C451001120A0A06424F4F4B4544100212150A11554E4445525F4D41494E54454E414E43451003120C0A0844454C495354454410042A3A0A0855736572526F6C6512190A15555345525F524F4C455F554E535045434946494544100012080A04484F5354100112090A0547554553541002329C080A0D52656E74616C5365727669636512460A0B41646450726F7065727479121A2E72656E74616C2E41646450726F7065727479526571756573741A1B2E72656E74616C2E41646450726F7065727479526573706F6E7365124F0A0E55706461746550726F7065727479121D2E72656E74616C2E55706461746550726F7065727479526571756573741A1E2E72656E74616C2E55706461746550726F7065727479526573706F6E7365124F0A0E52656D6F766550726F7065727479121D2E72656E74616C2E52656D6F766550726F7065727479526571756573741A1E2E72656E74616C2E52656D6F766550726F7065727479526573706F6E7365124F0A0E53656172636850726F7065727479121D2E72656E74616C2E53656172636850726F7065727479526571756573741A1E2E72656E74616C2E53656172636850726F7065727479526573706F6E736512490A0C426F6F6B50726F7065727479121B2E72656E74616C2E426F6F6B50726F7065727479526571756573741A1C2E72656E74616C2E426F6F6B50726F7065727479526573706F6E7365124F0A0E436F6E6669726D426F6F6B696E67121D2E72656E74616C2E436F6E6669726D426F6F6B696E67526571756573741A1E2E72656E74616C2E436F6E6669726D426F6F6B696E67526573706F6E736512430A0A5365617263685573657212192E72656E74616C2E53656172636855736572526571756573741A1A2E72656E74616C2E53656172636855736572526573706F6E7365124C0A0D536561726368426F6F6B696E67121C2E72656E74616C2E536561726368426F6F6B696E67526571756573741A1D2E72656E74616C2E536561726368426F6F6B696E67526573706F6E7365124C0A0D52656D6F7665426F6F6B696E67121C2E72656E74616C2E52656D6F7665426F6F6B696E67526571756573741A1D2E72656E74616C2E52656D6F7665426F6F6B696E67526573706F6E7365123A0A0B4372656174655573657273120C2E72656E74616C2E557365721A1B2E72656E74616C2E4372656174655573657273526573706F6E73652801124B0A174C697374417661696C61626C6550726F70657274696573121C2E72656E74616C2E4C697374417661696C61626C65526571756573741A102E72656E74616C2E50726F7065727479300112350A094C697374557365727312182E72656E74616C2E4C6973745573657273526571756573741A0C2E72656E74616C2E557365723001123E0A0C4C697374426F6F6B696E6773121B2E72656E74616C2E4C697374426F6F6B696E6773526571756573741A0F2E72656E74616C2E426F6F6B696E67300112530A134C69737452656D6F766564426F6F6B696E677312222E72656E74616C2E4C69737452656D6F766564426F6F6B696E6773526571756573741A162E72656E74616C2E52656D6F766564426F6F6B696E673001620670726F746F33";

public isolated client class RentalServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, RENTAL_DESC);
    }

    isolated remote function AddProperty(AddPropertyRequest|ContextAddPropertyRequest req) returns AddPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddPropertyRequest message;
        if req is ContextAddPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/AddProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <AddPropertyResponse>result;
    }

    isolated remote function AddPropertyContext(AddPropertyRequest|ContextAddPropertyRequest req) returns ContextAddPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddPropertyRequest message;
        if req is ContextAddPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/AddProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <AddPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function UpdateProperty(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns UpdatePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/UpdateProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <UpdatePropertyResponse>result;
    }

    isolated remote function UpdatePropertyContext(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns ContextUpdatePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/UpdateProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <UpdatePropertyResponse>result, headers: respHeaders};
    }

    isolated remote function RemoveProperty(RemovePropertyRequest|ContextRemovePropertyRequest req) returns RemovePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/RemoveProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <RemovePropertyResponse>result;
    }

    isolated remote function RemovePropertyContext(RemovePropertyRequest|ContextRemovePropertyRequest req) returns ContextRemovePropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/RemoveProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <RemovePropertyResponse>result, headers: respHeaders};
    }

    isolated remote function SearchProperty(SearchPropertyRequest|ContextSearchPropertyRequest req) returns SearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/SearchProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SearchPropertyResponse>result;
    }

    isolated remote function SearchPropertyContext(SearchPropertyRequest|ContextSearchPropertyRequest req) returns ContextSearchPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/SearchProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SearchPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function BookProperty(BookPropertyRequest|ContextBookPropertyRequest req) returns BookPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/BookProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookPropertyResponse>result;
    }

    isolated remote function BookPropertyContext(BookPropertyRequest|ContextBookPropertyRequest req) returns ContextBookPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/BookProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookPropertyResponse>result, headers: respHeaders};
    }

    isolated remote function ConfirmBooking(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ConfirmBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/ConfirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <ConfirmBookingResponse>result;
    }

    isolated remote function ConfirmBookingContext(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ContextConfirmBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/ConfirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <ConfirmBookingResponse>result, headers: respHeaders};
    }

    isolated remote function SearchUser(SearchUserRequest|ContextSearchUserRequest req) returns SearchUserResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchUserRequest message;
        if req is ContextSearchUserRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/SearchUser", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SearchUserResponse>result;
    }

    isolated remote function SearchUserContext(SearchUserRequest|ContextSearchUserRequest req) returns ContextSearchUserResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchUserRequest message;
        if req is ContextSearchUserRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/SearchUser", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SearchUserResponse>result, headers: respHeaders};
    }

    isolated remote function SearchBooking(SearchBookingRequest|ContextSearchBookingRequest req) returns SearchBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchBookingRequest message;
        if req is ContextSearchBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/SearchBooking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SearchBookingResponse>result;
    }

    isolated remote function SearchBookingContext(SearchBookingRequest|ContextSearchBookingRequest req) returns ContextSearchBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchBookingRequest message;
        if req is ContextSearchBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/SearchBooking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SearchBookingResponse>result, headers: respHeaders};
    }

    isolated remote function RemoveBooking(RemoveBookingRequest|ContextRemoveBookingRequest req) returns RemoveBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        RemoveBookingRequest message;
        if req is ContextRemoveBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/RemoveBooking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <RemoveBookingResponse>result;
    }

    isolated remote function RemoveBookingContext(RemoveBookingRequest|ContextRemoveBookingRequest req) returns ContextRemoveBookingResponse|grpc:Error {
        map<string|string[]> headers = {};
        RemoveBookingRequest message;
        if req is ContextRemoveBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/RemoveBooking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <RemoveBookingResponse>result, headers: respHeaders};
    }

    isolated remote function CreateUsers() returns CreateUsersStreamingClient|grpc:Error {
        grpc:StreamingClient sClient = check self.grpcClient->executeClientStreaming("rental.RentalService/CreateUsers");
        return new CreateUsersStreamingClient(sClient);
    }

    isolated remote function ListAvailableProperties(ListAvailableRequest|ContextListAvailableRequest req) returns stream<Property, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListAvailableRequest message;
        if req is ContextListAvailableRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return new stream<Property, grpc:Error?>(outputStream);
    }

    isolated remote function ListAvailablePropertiesContext(ListAvailableRequest|ContextListAvailableRequest req) returns ContextPropertyStream|grpc:Error {
        map<string|string[]> headers = {};
        ListAvailableRequest message;
        if req is ContextListAvailableRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return {content: new stream<Property, grpc:Error?>(outputStream), headers: respHeaders};
    }

    isolated remote function ListUsers(ListUsersRequest|ContextListUsersRequest req) returns stream<User, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListUsersRequest message;
        if req is ContextListUsersRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListUsers", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        UserStream outputStream = new UserStream(result);
        return new stream<User, grpc:Error?>(outputStream);
    }

    isolated remote function ListUsersContext(ListUsersRequest|ContextListUsersRequest req) returns ContextUserStream|grpc:Error {
        map<string|string[]> headers = {};
        ListUsersRequest message;
        if req is ContextListUsersRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListUsers", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        UserStream outputStream = new UserStream(result);
        return {content: new stream<User, grpc:Error?>(outputStream), headers: respHeaders};
    }

    isolated remote function ListBookings(ListBookingsRequest|ContextListBookingsRequest req) returns stream<Booking, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListBookingsRequest message;
        if req is ContextListBookingsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListBookings", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        BookingStream outputStream = new BookingStream(result);
        return new stream<Booking, grpc:Error?>(outputStream);
    }

    isolated remote function ListBookingsContext(ListBookingsRequest|ContextListBookingsRequest req) returns ContextBookingStream|grpc:Error {
        map<string|string[]> headers = {};
        ListBookingsRequest message;
        if req is ContextListBookingsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListBookings", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        BookingStream outputStream = new BookingStream(result);
        return {content: new stream<Booking, grpc:Error?>(outputStream), headers: respHeaders};
    }

    isolated remote function ListRemovedBookings(ListRemovedBookingsRequest|ContextListRemovedBookingsRequest req) returns stream<RemovedBooking, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListRemovedBookingsRequest message;
        if req is ContextListRemovedBookingsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListRemovedBookings", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        RemovedBookingStream outputStream = new RemovedBookingStream(result);
        return new stream<RemovedBooking, grpc:Error?>(outputStream);
    }

    isolated remote function ListRemovedBookingsContext(ListRemovedBookingsRequest|ContextListRemovedBookingsRequest req) returns ContextRemovedBookingStream|grpc:Error {
        map<string|string[]> headers = {};
        ListRemovedBookingsRequest message;
        if req is ContextListRemovedBookingsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/ListRemovedBookings", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        RemovedBookingStream outputStream = new RemovedBookingStream(result);
        return {content: new stream<RemovedBooking, grpc:Error?>(outputStream), headers: respHeaders};
    }
}

public isolated client class CreateUsersStreamingClient {
    private final grpc:StreamingClient sClient;

    isolated function init(grpc:StreamingClient sClient) {
        self.sClient = sClient;
    }

    isolated remote function sendUser(User message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function sendContextUser(ContextUser message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function receiveCreateUsersResponse() returns CreateUsersResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, _] = response;
            return <CreateUsersResponse>payload;
        }
    }

    isolated remote function receiveContextCreateUsersResponse() returns ContextCreateUsersResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, headers] = response;
            return {content: <CreateUsersResponse>payload, headers: headers};
        }
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.sClient->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.sClient->complete();
    }
}

public class PropertyStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|Property value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|Property value;|} nextRecord = {value: <Property>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public class UserStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|User value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|User value;|} nextRecord = {value: <User>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public class BookingStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|Booking value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|Booking value;|} nextRecord = {value: <Booking>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public class RemovedBookingStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|RemovedBooking value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|RemovedBooking value;|} nextRecord = {value: <RemovedBooking>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public isolated client class RentalServiceAddPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendAddPropertyResponse(AddPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextAddPropertyResponse(ContextAddPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceUserCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendUser(User response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextUser(ContextUser response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceBookPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBookPropertyResponse(BookPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBookPropertyResponse(ContextBookPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServicePropertyCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendProperty(Property response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextProperty(ContextProperty response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceRemovedBookingCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendRemovedBooking(RemovedBooking response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextRemovedBooking(ContextRemovedBooking response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceSearchPropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSearchPropertyResponse(SearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSearchPropertyResponse(ContextSearchPropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceBookingCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBooking(Booking response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBooking(ContextBooking response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceCreateUsersResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendCreateUsersResponse(CreateUsersResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextCreateUsersResponse(ContextCreateUsersResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceRemoveBookingResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendRemoveBookingResponse(RemoveBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextRemoveBookingResponse(ContextRemoveBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceSearchBookingResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSearchBookingResponse(SearchBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSearchBookingResponse(ContextSearchBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceRemovePropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendRemovePropertyResponse(RemovePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextRemovePropertyResponse(ContextRemovePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceConfirmBookingResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendConfirmBookingResponse(ConfirmBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextConfirmBookingResponse(ContextConfirmBookingResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceUpdatePropertyResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendUpdatePropertyResponse(UpdatePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextUpdatePropertyResponse(ContextUpdatePropertyResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceSearchUserResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSearchUserResponse(SearchUserResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSearchUserResponse(ContextSearchUserResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public type ContextUserStream record {|
    stream<User, error?> content;
    map<string|string[]> headers;
|};

public type ContextRemovedBookingStream record {|
    stream<RemovedBooking, error?> content;
    map<string|string[]> headers;
|};

public type ContextPropertyStream record {|
    stream<Property, error?> content;
    map<string|string[]> headers;
|};

public type ContextBookingStream record {|
    stream<Booking, error?> content;
    map<string|string[]> headers;
|};

public type ContextUser record {|
    User content;
    map<string|string[]> headers;
|};

public type ContextListRemovedBookingsRequest record {|
    ListRemovedBookingsRequest content;
    map<string|string[]> headers;
|};

public type ContextRemoveBookingResponse record {|
    RemoveBookingResponse content;
    map<string|string[]> headers;
|};

public type ContextSearchUserRequest record {|
    SearchUserRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchUserResponse record {|
    SearchUserResponse content;
    map<string|string[]> headers;
|};

public type ContextRemovedBooking record {|
    RemovedBooking content;
    map<string|string[]> headers;
|};

public type ContextAddPropertyResponse record {|
    AddPropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextRemoveBookingRequest record {|
    RemoveBookingRequest content;
    map<string|string[]> headers;
|};

public type ContextAddPropertyRequest record {|
    AddPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyResponse record {|
    RemovePropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextProperty record {|
    Property content;
    map<string|string[]> headers;
|};

public type ContextBookPropertyResponse record {|
    BookPropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyResponse record {|
    UpdatePropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextBookPropertyRequest record {|
    BookPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextListUsersRequest record {|
    ListUsersRequest content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyRequest record {|
    UpdatePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextListBookingsRequest record {|
    ListBookingsRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyResponse record {|
    SearchPropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextBooking record {|
    Booking content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingRequest record {|
    ConfirmBookingRequest content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingResponse record {|
    ConfirmBookingResponse content;
    map<string|string[]> headers;
|};

public type ContextListAvailableRequest record {|
    ListAvailableRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchBookingRequest record {|
    SearchBookingRequest content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyRequest record {|
    RemovePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchBookingResponse record {|
    SearchBookingResponse content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyRequest record {|
    SearchPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextCreateUsersResponse record {|
    CreateUsersResponse content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type User record {|
    string user_id = "";
    string name = "";
    string email = "";
    UserRole role = USER_ROLE_UNSPECIFIED;
    string region = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ListRemovedBookingsRequest record {|
    string guest_id = "";
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemoveBookingResponse record {|
    boolean success = false;
    string message = "";
    RemovedBooking removed_booking = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchUserRequest record {|
    string user_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type DateRange record {|
    string check_in = "";
    string check_out = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchUserResponse record {|
    boolean found = false;
    string message = "";
    User user = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemovedBooking record {|
    Booking booking = {};
    string reason = "";
    string removed_at = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type AddPropertyResponse record {|
    string property_id = "";
    boolean success = false;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemoveBookingRequest record {|
    string booking_id = "";
    string reason = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type AddPropertyRequest record {|
    string host_id = "";
    string name = "";
    string location = "";
    string region = "";
    string property_type = "";
    float price_per_night = 0.0;
    string description = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemovePropertyResponse record {|
    boolean success = false;
    string message = "";
    Property[] remaining_properties = [];
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type Property record {|
    string property_id = "";
    string host_id = "";
    string name = "";
    string location = "";
    string region = "";
    string property_type = "";
    float price_per_night = 0.0;
    PropertyStatus status = PROPERTY_STATUS_UNSPECIFIED;
    string description = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookPropertyResponse record {|
    boolean success = false;
    string message = "";
    string cart_id = "";
    float estimated_cost = 0.0;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UpdatePropertyResponse record {|
    boolean success = false;
    string message = "";
    Property property = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookPropertyRequest record {|
    string guest_id = "";
    string property_id = "";
    DateRange dates = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ListUsersRequest record {|
    UserRole role_filter = USER_ROLE_UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UpdatePropertyRequest record {|
    string property_id = "";
    float price_per_night?;
    string description?;
    PropertyStatus status?;
|};

isolated function isValidUpdatepropertyrequest(UpdatePropertyRequest r) returns boolean {
    int _price_per_nightCount = 0;
    if r?.price_per_night !is () {
        _price_per_nightCount += 1;
    }
    int _descriptionCount = 0;
    if r?.description !is () {
        _descriptionCount += 1;
    }
    int _statusCount = 0;
    if r?.status !is () {
        _statusCount += 1;
    }
    if _price_per_nightCount > 1 || _descriptionCount > 1 || _statusCount > 1 {
        return false;
    }
    return true;
}

isolated function setUpdatePropertyRequest_PricePerNight(UpdatePropertyRequest r, float price_per_night) {
    r.price_per_night = price_per_night;
}

isolated function setUpdatePropertyRequest_Description(UpdatePropertyRequest r, string description) {
    r.description = description;
}

isolated function setUpdatePropertyRequest_Status(UpdatePropertyRequest r, PropertyStatus status) {
    r.status = status;
}

@protobuf:Descriptor {value: RENTAL_DESC}
public type ListBookingsRequest record {|
    string guest_id = "";
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchPropertyResponse record {|
    boolean available = false;
    string message = "";
    Property property = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type Booking record {|
    string booking_id = "";
    string property_id = "";
    string guest_id = "";
    DateRange dates = {};
    float total_cost = 0.0;
    string status = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ConfirmBookingRequest record {|
    string guest_id = "";
    string cart_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ConfirmBookingResponse record {|
    boolean success = false;
    string message = "";
    Booking booking = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ListAvailableRequest record {|
    string location_filter = "";
    float min_price = 0.0;
    float max_price = 0.0;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchBookingRequest record {|
    string booking_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemovePropertyRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchBookingResponse record {|
    boolean found = false;
    boolean removed = false;
    string message = "";
    Booking booking = {};
    RemovedBooking removed_booking = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchPropertyRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type CreateUsersResponse record {|
    int created_count = 0;
    string message = "";
    User[] created_users = [];
|};

public enum PropertyStatus {
    PROPERTY_STATUS_UNSPECIFIED, AVAILABLE, BOOKED, UNDER_MAINTENANCE, DELISTED
}

public enum UserRole {
    USER_ROLE_UNSPECIFIED, HOST, GUEST
}
