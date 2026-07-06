import { CAMPUS_LOCATIONS, type CampusLocation } from './data/campus-locations.js';

const byId = new Map<string, CampusLocation>(CAMPUS_LOCATIONS.map((loc) => [loc.id, loc]));

export const LOCATION_IDS = CAMPUS_LOCATIONS.map((loc) => loc.id) as [string, ...string[]];

export function listLocations(): CampusLocation[] {
    return CAMPUS_LOCATIONS;
}

export function resolveLocation(id: string): CampusLocation | undefined {
    return byId.get(id);
}