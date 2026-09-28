import '../models/board_space.dart';
import '../models/property.dart';
import '../models/event_card.dart';

class GameData {
  static final List<BoardSpace> spaces = [
    const BoardSpace(index: 0, name: "NAATTILE THUDAKKAM", type: SpaceType.start),
    const BoardSpace(index: 1, name: "Vengeri", type: SpaceType.property, propertyId: "prop_01"),
    const BoardSpace(index: 2, name: "Vishu", type: SpaceType.communityChest),
    const BoardSpace(index: 3, name: "Beypore", type: SpaceType.property, propertyId: "prop_02"),
    const BoardSpace(index: 4, name: "Property Tax", type: SpaceType.tax, feeAmount: 2000),
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
    const BoardSpace(index: 38, name: "Panchayath Tax", type: SpaceType.tax, feeAmount: 1000),
    const BoardSpace(index: 39, name: "Kovalam", type: SpaceType.property, propertyId: "prop_22"),
  ];

  static final Map<String, Property> initialProperties = {
    // Malabar (Brown)
    "prop_01": Property(id: "prop_01", name: "Vengeri", group: PropertyGroup.malabar, price: 6000, rent: [200, 1000, 3000, 9000, 16000, 25000], upgradeCost: 5000, mortgageValue: 3000),
    "prop_02": Property(id: "prop_02", name: "Beypore", group: PropertyGroup.malabar, price: 6000, rent: [400, 2000, 6000, 18000, 32000, 45000], upgradeCost: 5000, mortgageValue: 3000),
    "prop_03": Property(id: "prop_03", name: "Nilambur", group: PropertyGroup.malabar, price: 8000, rent: [400, 2000, 6000, 18000, 32000, 45000], upgradeCost: 5000, mortgageValue: 4000),
    
    // Kochi (Pink)
    "prop_04": Property(id: "prop_04", name: "Payyanur", group: PropertyGroup.kochi, price: 10000, rent: [600, 3000, 9000, 27000, 40000, 55000], upgradeCost: 5000, mortgageValue: 5000),
    "prop_05": Property(id: "prop_05", name: "Fort Kochi", group: PropertyGroup.kochi, price: 10000, rent: [600, 3000, 9000, 27000, 40000, 55000], upgradeCost: 5000, mortgageValue: 5000),
    "prop_06": Property(id: "prop_06", name: "Marine Drive", group: PropertyGroup.kochi, price: 12000, rent: [800, 4000, 10000, 30000, 45000, 60000], upgradeCost: 5000, mortgageValue: 6000),

    // Thrissur (Light Blue)
    "prop_07": Property(id: "prop_07", name: "Mattancherry", group: PropertyGroup.thrissur, price: 14000, rent: [1000, 5000, 15000, 45000, 62000, 75000], upgradeCost: 10000, mortgageValue: 7000),
    "prop_08": Property(id: "prop_08", name: "Vyttila", group: PropertyGroup.thrissur, price: 14000, rent: [1000, 5000, 15000, 45000, 62000, 75000], upgradeCost: 10000, mortgageValue: 7000),
    "prop_09": Property(id: "prop_09", name: "Swaraj Round", group: PropertyGroup.thrissur, price: 16000, rent: [1200, 6000, 18000, 50000, 70000, 90000], upgradeCost: 10000, mortgageValue: 8000),

    // Backwaters (Orange)
    "prop_10": Property(id: "prop_10", name: "Vadakkunnathan", group: PropertyGroup.backwaters, price: 18000, rent: [1400, 7000, 20000, 55000, 75000, 95000], upgradeCost: 10000, mortgageValue: 9000),
    "prop_11": Property(id: "prop_11", name: "Athirappilly", group: PropertyGroup.backwaters, price: 18000, rent: [1400, 7000, 20000, 55000, 75000, 95000], upgradeCost: 10000, mortgageValue: 9000),
    "prop_12": Property(id: "prop_12", name: "Guruvayur", group: PropertyGroup.backwaters, price: 20000, rent: [1600, 8000, 22000, 60000, 80000, 100000], upgradeCost: 10000, mortgageValue: 10000),

    // Highlands (Red)
    "prop_13": Property(id: "prop_13", name: "Alappuzha", group: PropertyGroup.highlands, price: 22000, rent: [1800, 9000, 25000, 70000, 87000, 105000], upgradeCost: 15000, mortgageValue: 11000),
    "prop_14": Property(id: "prop_14", name: "Kumarakom", group: PropertyGroup.highlands, price: 22000, rent: [1800, 9000, 25000, 70000, 87000, 105000], upgradeCost: 15000, mortgageValue: 11000),
    "prop_15": Property(id: "prop_15", name: "Kuttanad", group: PropertyGroup.highlands, price: 24000, rent: [2000, 10000, 30000, 75000, 92000, 110000], upgradeCost: 15000, mortgageValue: 12000),

    // South Kerala (Yellow)
    "prop_16": Property(id: "prop_16", name: "Ashtamudi", group: PropertyGroup.southKerala, price: 26000, rent: [2200, 11000, 33000, 80000, 97000, 115000], upgradeCost: 15000, mortgageValue: 13000),
    "prop_17": Property(id: "prop_17", name: "Munnar", group: PropertyGroup.southKerala, price: 26000, rent: [2200, 11000, 33000, 80000, 97000, 115000], upgradeCost: 15000, mortgageValue: 13000),
    "prop_18": Property(id: "prop_18", name: "Wayanad", group: PropertyGroup.southKerala, price: 28000, rent: [2400, 12000, 36000, 85000, 102000, 120000], upgradeCost: 15000, mortgageValue: 14000),

    // Premium (Green)
    "prop_19": Property(id: "prop_19", name: "Vagamon", group: PropertyGroup.premium, price: 30000, rent: [2600, 13000, 39000, 90000, 110000, 127000], upgradeCost: 20000, mortgageValue: 15000),
    "prop_20": Property(id: "prop_20", name: "Thekkady", group: PropertyGroup.premium, price: 30000, rent: [2600, 13000, 39000, 90000, 110000, 127000], upgradeCost: 20000, mortgageValue: 15000),
    "prop_21": Property(id: "prop_21", name: "Bekal Fort", group: PropertyGroup.premium, price: 32000, rent: [2800, 15000, 45000, 100000, 120000, 140000], upgradeCost: 20000, mortgageValue: 16000),

    // Luxury (Dark Blue)
    "prop_22": Property(id: "prop_22", name: "Kovalam", group: PropertyGroup.luxury, price: 35000, rent: [3500, 17500, 50000, 110000, 130000, 150000], upgradeCost: 20000, mortgageValue: 17500),

    // Transports
    "trans_01": Property(id: "trans_01", name: "KSRTC Stand", group: PropertyGroup.transport, price: 20000, rent: [2500, 5000, 10000, 20000, 0, 0], upgradeCost: 0, mortgageValue: 10000),
    "trans_02": Property(id: "trans_02", name: "Kochi Metro", group: PropertyGroup.transport, price: 20000, rent: [2500, 5000, 10000, 20000, 0, 0], upgradeCost: 0, mortgageValue: 10000),
    "trans_03": Property(id: "trans_03", name: "Ferry", group: PropertyGroup.transport, price: 20000, rent: [2500, 5000, 10000, 20000, 0, 0], upgradeCost: 0, mortgageValue: 10000),
    "trans_04": Property(id: "trans_04", name: "Airport", group: PropertyGroup.transport, price: 20000, rent: [2500, 5000, 10000, 20000, 0, 0], upgradeCost: 0, mortgageValue: 10000),

    // Utilities
    "util_01": Property(id: "util_01", name: "KSEB", group: PropertyGroup.utility, price: 15000, rent: [0, 0, 0, 0, 0, 0], upgradeCost: 0, mortgageValue: 7500),
    "util_02": Property(id: "util_02", name: "Water Authority", group: PropertyGroup.utility, price: 15000, rent: [0, 0, 0, 0, 0, 0], upgradeCost: 0, mortgageValue: 7500),
  };

  static final List<EventCard> chanceCards = [
    const EventCard(id: "c1", title: "Heavy Monsoon", description: "Heavy rain damages your property. Pay ₹2,500.", type: EventCardType.moneyPenalty, amount: 2500),
    const EventCard(id: "c2", title: "Hartal", description: "Unexpected disruption slows the town. Skip your next turn or pay ₹1,000.", type: EventCardType.moneyPenalty, amount: 1000), // Simplified
    const EventCard(id: "c3", title: "Tourist Season", description: "Tourist traffic increases! Receive ₹3,000.", type: EventCardType.moneyReward, amount: 3000),
    const EventCard(id: "c4", title: "Go to Kochi Metro", description: "Advance to Kochi Metro.", type: EventCardType.moveToSpace, destinationIndex: 15),
    const EventCard(id: "c5", title: "Speeding Ticket", description: "Caught speeding in Wayanad ghats. Pay ₹1,500.", type: EventCardType.moneyPenalty, amount: 1500),
    const EventCard(id: "c6", title: "Go to Jail", description: "Go directly to Police Station. Do not pass start.", type: EventCardType.goToJail),
    const EventCard(id: "c7", title: "Advance to Start", description: "Advance to NAATTILE THUDAKKAM.", type: EventCardType.moveToSpace, destinationIndex: 0),
    const EventCard(id: "c8", title: "Property Repairs", description: "Pay for repairs. ₹2,500 per house, ₹10,000 per resort.", type: EventCardType.payPerHouse, houseFee: 2500, resortFee: 10000),
  ];

  static final List<EventCard> communityChestCards = [
    const EventCard(id: "cc1", title: "Onam Sadya", description: "Your grand Onam celebration attracts visitors. Receive ₹5,000.", type: EventCardType.moneyReward, amount: 5000),
    const EventCard(id: "cc2", title: "Vishu Kaineettam", description: "Unexpected Vishu kaineettam! Receive ₹3,000.", type: EventCardType.moneyReward, amount: 3000),
    const EventCard(id: "cc3", title: "Chaya Break", description: "Take a quick tea break. Receive ₹1,000.", type: EventCardType.moneyReward, amount: 1000),
    const EventCard(id: "cc4", title: "Hospital Bill", description: "Pay hospital bill ₹5,000.", type: EventCardType.moneyPenalty, amount: 5000),
    const EventCard(id: "cc5", title: "Lottery Won", description: "You won the Kerala State Lottery! Receive ₹10,000.", type: EventCardType.moneyReward, amount: 10000),
    const EventCard(id: "cc6", title: "Get Out of Jail", description: "Get out of Police Station free.", type: EventCardType.getOutOfJail),
    const EventCard(id: "cc7", title: "Advance to Start", description: "Advance to NAATTILE THUDAKKAM.", type: EventCardType.moveToSpace, destinationIndex: 0),
  ];
}
