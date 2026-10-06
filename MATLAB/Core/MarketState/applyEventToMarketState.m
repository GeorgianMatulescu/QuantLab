function state = applyEventToMarketState(state, eventRow)
eventType = string(eventRow.event_type(1));
payload = eventRow.payload{1};
switch eventType
    case "NEW_SESSION"
        state.session.is_active = true;
    case "SESSION_CLOSED"
        state.session.is_active = false;
    case "ORB_COMPLETED"
        state.session.orb_completed = true;
        state.session.orb_open = payload.orb_open;
        state.session.orb_high = payload.orb_high;
        state.session.orb_low = payload.orb_low;
        state.session.orb_close = payload.orb_close;
    case "SWING_HIGH"
        state.structure.last_swing_high_price = eventRow.price(1);
        state.structure.last_swing_high_time = eventRow.event_time(1);
        state.structure.swing_high_count = state.structure.swing_high_count + 1;
    case "SWING_LOW"
        state.structure.last_swing_low_price = eventRow.price(1);
        state.structure.last_swing_low_time = eventRow.event_time(1);
        state.structure.swing_low_count = state.structure.swing_low_count + 1;
end
end
