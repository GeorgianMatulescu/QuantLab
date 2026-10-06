function state = resetMarketStateForSession(state, sessionDate, firstBar)
state.clock.session_date = sessionDate;
state.clock.current_time = firstBar.datetime_new_york(1);
state.session.is_active = true;
state.session.bars_seen = 0;
state.session.session_open = firstBar.open(1);
state.session.session_high = firstBar.high(1);
state.session.session_low = firstBar.low(1);
state.session.session_close = firstBar.close(1);
state.session.orb_completed = false;
state.session.orb_open = NaN;
state.session.orb_high = NaN;
state.session.orb_low = NaN;
state.session.orb_close = NaN;
state.execution.trade_active = false;
end
