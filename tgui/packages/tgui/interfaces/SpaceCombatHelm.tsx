// Helm: flight status and basic controls plus the PDC. Real flying happens in the ship view (W/S, A/D, Q/E, Shift, Alt, X).
import { Box, Button, LabeledList, Section } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { DradisContent } from './SpaceCombatDradis';

type Data = {
  name: string;
  heading: number;
  desired_heading: number;
  speed: number;
  max_speed: number;
  throttle: number;
  dampeners: BooleanLike;
  brakes: BooleanLike;
  boost_ready: BooleanLike;
  weapons: { index: number; name: string; ammo: number; cooldown_left: number; error: string | null; selected: BooleanLike }[];
};

export const SpaceCombatHelm = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Window width={700} height={900} theme="hackerman">
      <Window.Content>
        <Section title={data.name}>
          <LabeledList>
            <LabeledList.Item label="Heading">
              {data.heading}° (ordered {data.desired_heading}°)
            </LabeledList.Item>
            <LabeledList.Item label="Speed">
              {data.speed} / {data.max_speed}
            </LabeledList.Item>
            <LabeledList.Item label="Throttle">
              {[0, 25, 50, 75, 100].map((v) => (
                <Button
                  key={v}
                  selected={data.throttle === v}
                  onClick={() => act('throttle', { value: v })}
                >
                  {v}
                </Button>
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Turn">
              {[-90, -45, -15, 15, 45, 90].map((v) => (
                <Button key={v} onClick={() => act('turn', { value: v })}>
                  {v > 0 ? `+${v}` : v}
                </Button>
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Systems">
              <Button
                color={data.dampeners ? 'good' : 'default'}
                onClick={() => act('dampeners')}
              >
                IAS {data.dampeners ? 'ON' : 'OFF'}
              </Button>
              <Button
                color={data.brakes ? 'bad' : 'default'}
                onClick={() => act('brakes')}
              >
                Brakes
              </Button>
              <Button
                color="average"
                disabled={!data.boost_ready}
                onClick={() => act('boost')}
              >
                Boost
              </Button>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Weapons (Space cycles, left click fires)">
          {(data.weapons || []).map((w) => (
            <Box key={w.index}>
              <Button
                selected={!!w.selected}
                onClick={() => act('select_weapon', { index: w.index })}
              >
                {w.index}. {w.name}
              </Button>
              <Box inline ml={1} color={w.error ? 'average' : 'good'}>
                {w.error ? w.error : 'READY'}
                {w.ammo >= 0 ? ` (ammo ${w.ammo})` : ''}
              </Box>
            </Box>
          ))}
        </Section>
        <DradisContent height="360px" />
        <Box color="label" p={1}>
          W/S thrust, A/D turn (strafe with IAS off), Q/E rotate, Shift boost,
          Alt brakes, X IAS, left click fires the selected weapon (railgun fires forward).
        </Box>
      </Window.Content>
    </Window>
  );
};
