import '../models/board_space.dart';
import '../models/property.dart';
import '../models/event_card.dart';

class GameData {
  static final List<BoardSpace> spaces = [
    const BoardSpace(index: 0, name: "NAATTILE THUDAKKAM", type: SpaceType.start),
    const BoardSpace(index: 1, name: "Vengeri", type: SpaceType.property, propertyId: "prop_01"),
    const BoardSpace(index: 2, name: "Vishu", type: SpaceType.communityChest),
    const BoardSpace(index: 3, name: "Beypore", type: SpaceType.property, propertyId: "prop_02"),
    const BoardSpace(index: 4, name: "Property Tax", type: SpaceType.tax, feeAmount: 100),
    const BoardSpace(index: 5, name: "KSRTC Stand", type: SpaceType.railroad, propertyId: "trans_01"),
    const BoardSpace(index: 6, name: "Nilambur", type: SpaceType.property, propertyId: "prop_03"),
    const BoardSpace(index: 7, name: "Monsoon", type: SpaceType.chance),
    const BoardSpace(index: 8, name: "Payyanur", type: SpaceType.property, propertyId: "prop_04"),
    const BoardSpace(index: 9, name: "Fort Kochi", type: SpaceType.property, propertyId: "prop_05"),
    const BoardSpace(index: 10, name: "Hospital", type: SpaceType.jail),
    const BoardSpace(index: 11, name: "Marine Drive", type: SpaceType.property, propertyId: "prop_06"),
    const BoardSpace(index: 12, name: "KSEB", type: SpaceType.utility, propertyId: "util_01"),
    const BoardSpace(index: 13, name: "Mattancherry", type: SpaceType.property, propertyId: "prop_07"),
    const BoardSpace(index: 14, name: "Vyttila", type: SpaceType.property, propertyId: "prop_08"),
    const BoardSpace(index: 15, name: "Kochi Metro", type: SpaceType.railroad, propertyId: "trans_02"),
    const BoardSpace(index: 16, name: "Swaraj Round", type: SpaceType.property, propertyId: "prop_09"),
    const BoardSpace(index: 17, name: "Onam", type: SpaceType.communityChest),
    const BoardSpace(index: 18, name: "Vadakkunnathan", type: SpaceType.property, propertyId: "prop_10"),
    const BoardSpace(index: 19, name: "Athirappilly", type: SpaceType.property, propertyId: "prop_11"),
    const BoardSpace(index: 20, name: "Chaya Kada", type: SpaceType.freeParking),
    const BoardSpace(index: 21, name: "Guruvayur", type: SpaceType.property, propertyId: "prop_12"),
    const BoardSpace(index: 22, name: "Monsoon", type: SpaceType.chance),
    const BoardSpace(index: 23, name: "Alappuzha", type: SpaceType.property, propertyId: "prop_13"),
    const BoardSpace(index: 24, name: "Kumarakom", type: SpaceType.property, propertyId: "prop_14"),
    const BoardSpace(index: 25, name: "Ferry", type: SpaceType.railroad, propertyId: "trans_03"),
    const BoardSpace(index: 26, name: "Kuttanad", type: SpaceType.property, propertyId: "prop_15"),
    const BoardSpace(index: 27, name: "Ashtamudi", type: SpaceType.property, propertyId: "prop_16"),
    const BoardSpace(index: 28, name: "Water Authority", type: SpaceType.utility, propertyId: "util_02"),
    const BoardSpace(index: 29, name: "Munnar", type: SpaceType.property, propertyId: "prop_17"),
    const BoardSpace(index: 30, name: "Police Station", type: SpaceType.goToJail),
    const BoardSpace(index: 31, name: "Wayanad", type: SpaceType.property, propertyId: "prop_18"),
    const BoardSpace(index: 32, name: "Vagamon", type: SpaceType.property, propertyId: "prop_19"),
    const BoardSpace(index: 33, name: "Vishu", type: SpaceType.communityChest),
    const BoardSpace(index: 34, name: "Thekkady", type: SpaceType.property, propertyId: "prop_20"),
    const BoardSpace(index: 35, name: "Airport", type: SpaceType.railroad, propertyId: "trans_04"),
    const BoardSpace(index: 36, name: "Monsoon", type: SpaceType.chance),
    const BoardSpace(index: 37, name: "Bekal Fort", type: SpaceType.property, propertyId: "prop_21"),
    const BoardSpace(index: 38, name: "Panchayath Tax", type: SpaceType.tax, feeAmount: 50),
    const BoardSpace(index: 39, name: "Kovalam", type: SpaceType.property, propertyId: "prop_22"),
  ];

  static final Map<String, Property> initialProperties = {
    // Malabar (Brown)
    "prop_01": Property(id: "prop_01", name: "Vengeri", group: PropertyGroup.malabar, price: 60, rent: [2, 10, 30, 90, 160, 250], upgradeCost: 50, mortgageValue: 30),
    "prop_02": Property(id: "prop_02", name: "Beypore", group: PropertyGroup.malabar, price: 60, rent: [4, 20, 60, 180, 320, 450], upgradeCost: 50, mortgageValue: 30),
    "prop_03": Property(id: "prop_03", name: "Nilambur", group: PropertyGroup.malabar, price: 80, rent: [4, 20, 60, 180, 320, 450], upgradeCost: 50, mortgageValue: 40),
    
    // Kochi (Pink)
    "prop_04": Property(id: "prop_04", name: "Payyanur", group: PropertyGroup.kochi, price: 100, rent: [6, 30, 90, 270, 400, 550], upgradeCost: 50, mortgageValue: 50),
    "prop_05": Property(id: "prop_05", name: "Fort Kochi", group: PropertyGroup.kochi, price: 100, rent: [6, 30, 90, 270, 400, 550], upgradeCost: 50, mortgageValue: 50),
    "prop_06": Property(id: "prop_06", name: "Marine Drive", group: PropertyGroup.kochi, price: 120, rent: [8, 40, 100, 300, 450, 600], upgradeCost: 50, mortgageValue: 60),

    // Thrissur (Light Blue)
    "prop_07": Property(id: "prop_07", name: "Mattancherry", group: PropertyGroup.thrissur, price: 140, rent: [10, 50, 150, 450, 620, 750], upgradeCost: 100, mortgageValue: 70),
    "prop_08": Property(id: "prop_08", name: "Vyttila", group: PropertyGroup.thrissur, price: 140, rent: [10, 50, 150, 450, 620, 750], upgradeCost: 100, mortgageValue: 70),
    "prop_09": Property(id: "prop_09", name: "Swaraj Round", group: PropertyGroup.thrissur, price: 160, rent: [12, 60, 180, 500, 700, 900], upgradeCost: 100, mortgageValue: 80),

    // Backwaters (Orange)
    "prop_10": Property(id: "prop_10", name: "Vadakkunnathan", group: PropertyGroup.backwaters, price: 180, rent: [14, 70, 200, 550, 750, 950], upgradeCost: 100, mortgageValue: 90),
    "prop_11": Property(id: "prop_11", name: "Athirappilly", group: PropertyGroup.backwaters, price: 180, rent: [14, 70, 200, 550, 750, 950], upgradeCost: 100, mortgageValue: 90),
    "prop_12": Property(id: "prop_12", name: "Guruvayur", group: PropertyGroup.backwaters, price: 200, rent: [16, 80, 220, 600, 800, 1000], upgradeCost: 100, mortgageValue: 100),

    // Highlands (Red)
    "prop_13": Property(id: "prop_13", name: "Alappuzha", group: PropertyGroup.highlands, price: 220, rent: [18, 90, 250, 700, 870, 1050], upgradeCost: 150, mortgageValue: 110),
    "prop_14": Property(id: "prop_14", name: "Kumarakom", group: PropertyGroup.highlands, price: 220, rent: [18, 90, 250, 700, 870, 1050], upgradeCost: 150, mortgageValue: 110),
    "prop_15": Property(id: "prop_15", name: "Kuttanad", group: PropertyGroup.highlands, price: 240, rent: [20, 100, 300, 750, 920, 1100], upgradeCost: 150, mortgageValue: 120),

    // South Kerala (Yellow)
    "prop_16": Property(id: "prop_16", name: "Ashtamudi", group: PropertyGroup.southKerala, price: 260, rent: [22, 110, 330, 800, 970, 1150], upgradeCost: 150, mortgageValue: 130),
    "prop_17": Property(id: "prop_17", name: "Munnar", group: PropertyGroup.southKerala, price: 260, rent: [22, 110, 330, 800, 970, 1150], upgradeCost: 150, mortgageValue: 130),
    "prop_18": Property(id: "prop_18", name: "Wayanad", group: PropertyGroup.southKerala, price: 280, rent: [24, 120, 360, 850, 1020, 1200], upgradeCost: 150, mortgageValue: 140),

    // Premium (Green)
    "prop_19": Property(id: "prop_19", name: "Vagamon", group: PropertyGroup.premium, price: 300, rent: [26, 130, 390, 900, 1100, 1270], upgradeCost: 200, mortgageValue: 150),
    "prop_20": Property(id: "prop_20", name: "Thekkady", group: PropertyGroup.premium, price: 300, rent: [26, 130, 390, 900, 1100, 1270], upgradeCost: 200, mortgageValue: 150),
    "prop_21": Property(id: "prop_21", name: "Bekal Fort", group: PropertyGroup.premium, price: 320, rent: [28, 150, 450, 1000, 1200, 1400], upgradeCost: 200, mortgageValue: 160),

    // Luxury (Dark Blue)
    "prop_22": Property(id: "prop_22", name: "Kovalam", group: PropertyGroup.luxury, price: 350, rent: [35, 175, 500, 1100, 1300, 1500], upgradeCost: 200, mortgageValue: 175),

    // Transports
    "trans_01": Property(id: "trans_01", name: "KSRTC Stand", group: PropertyGroup.transport, price: 200, rent: [25, 50, 100, 200, 0, 0], upgradeCost: 0, mortgageValue: 100),
    "trans_02": Property(id: "trans_02", name: "Kochi Metro", group: PropertyGroup.transport, price: 200, rent: [25, 50, 100, 200, 0, 0], upgradeCost: 0, mortgageValue: 100),
    "trans_03": Property(id: "trans_03", name: "Ferry", group: PropertyGroup.transport, price: 200, rent: [25, 50, 100, 200, 0, 0], upgradeCost: 0, mortgageValue: 100),
    "trans_04": Property(id: "trans_04", name: "Airport", group: PropertyGroup.transport, price: 200, rent: [25, 50, 100, 200, 0, 0], upgradeCost: 0, mortgageValue: 100),

    // Utilities
    "util_01": Property(id: "util_01", name: "KSEB", group: PropertyGroup.utility, price: 150, rent: [0, 0, 0, 0, 0, 0], upgradeCost: 0, mortgageValue: 75),
    "util_02": Property(id: "util_02", name: "Water Authority", group: PropertyGroup.utility, price: 150, rent: [0, 0, 0, 0, 0, 0], upgradeCost: 0, mortgageValue: 75),
  };

  static final List<EventCard> chanceCards = [
    const EventCard(id: "c1", title: "Heavy Monsoon", description: "Heavy rain damages your property. Pay ₹25.", type: EventCardType.moneyPenalty, amount: 25),
    const EventCard(id: "c2", title: "Hartal", description: "Unexpected disruption slows the town. Skip your next turn or pay ₹10.", type: EventCardType.moneyPenalty, amount: 10),
    const EventCard(id: "c3", title: "Tourist Season", description: "Tourist traffic increases! Receive ₹30.", type: EventCardType.moneyReward, amount: 30),
    const EventCard(id: "c4", title: "Go to Kochi Metro", description: "Advance to Kochi Metro.", type: EventCardType.moveToSpace, destinationIndex: 15),
    const EventCard(id: "c5", title: "Speeding Ticket", description: "Caught speeding in Wayanad ghats. Pay ₹15.", type: EventCardType.moneyPenalty, amount: 15),
    const EventCard(id: "c6", title: "Go to Jail", description: "Go directly to Police Station. Do not pass start.", type: EventCardType.goToJail),
    const EventCard(id: "c7", title: "Advance to Start", description: "Advance to NAATTILE THUDAKKAM.", type: EventCardType.moveToSpace, destinationIndex: 0),
    const EventCard(id: "c8", title: "Property Repairs", description: "Pay for repairs. ₹25 per house, ₹100 per resort.", type: EventCardType.payPerHouse, houseFee: 25, resortFee: 100),
  ];

  static final List<EventCard> communityChestCards = [
    const EventCard(id: "cc1", title: "Onam Sadya", description: "Your grand Onam celebration attracts visitors. Receive ₹50.", type: EventCardType.moneyReward, amount: 50),
    const EventCard(id: "cc2", title: "Vishu Kaineettam", description: "Unexpected Vishu kaineettam! Receive ₹30.", type: EventCardType.moneyReward, amount: 30),
    const EventCard(id: "cc3", title: "Chaya Break", description: "Take a quick tea break. Receive ₹10.", type: EventCardType.moneyReward, amount: 10),
    const EventCard(id: "cc4", title: "Hospital Bill", description: "Pay hospital bill ₹50.", type: EventCardType.moneyPenalty, amount: 50),
    const EventCard(id: "cc5", title: "Lottery Won", description: "You won the Kerala State Lottery! Receive ₹100.", type: EventCardType.moneyReward, amount: 100),
    const EventCard(id: "cc6", title: "Get Out of Jail", description: "Get out of Police Station free.", type: EventCardType.getOutOfJail),
    const EventCard(id: "cc7", title: "Advance to Start", description: "Advance to NAATTILE THUDAKKAM.", type: EventCardType.moveToSpace, destinationIndex: 0),
  ];
}
