// Port of NSV13's TacticalConsole: ship status and armaments. Weapons are fired with 1-3 / click in the ship view.
import {
  Box,
  Button,
  LabeledList,
  ProgressBar,
  Section,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Weapon = {
  index: number;
  name: string;
  damage: number;
  range: number;
  arc: number;
  ammo: number;
  max_ammo: number;
  priority: number;
  controllers: string;
  cooldown_left: number;
  error: string | null;
  selected: BooleanLike;
};

type Data = {
  name: string;
  hull: number;
  max_hull: number;
  max_armour: number;
  armour: { name: string; value: number }[];
  weapons: Weapon[];
  observing: BooleanLike;
  is_admin: BooleanLike;
  log: string[];
};

const armourRanges = {
  good: [0.66, Infinity],
  average: [0.33, 0.66],
  bad: [-Infinity, 0.33],
} as Record<string, [number, number]>;

export const SpaceCombatTactical = () => {
  const { act, data } = useBackend<Data>();
  const { weapons = [], armour = [], log = [] } = data;
  return (
    <Window width={560} height={600}>
      <Window.Content scrollable>
        <Section title="Ship status">
          <Section title="Hull integrity:">
            <ProgressBar
              value={data.hull / data.max_hull}
              ranges={{
                good: [0.9, Infinity],
                average: [0.15, 0.9],
                bad: [-Infinity, 0.15],
              }}
            />
          </Section>
          <Section title="Armour:">
            <LabeledList>
              {armour.map((a) => (
                <LabeledList.Item key={a.name} label={a.name}>
                  <ProgressBar
                    value={a.value / data.max_armour}
                    ranges={armourRanges}
                  />
                </LabeledList.Item>
              ))}
            </LabeledList>
          </Section>
        </Section>
        <Section title="Armaments:">
          <LabeledList>
            {weapons.map((w) => (
              <LabeledList.Item
                key={w.index}
                label={`${w.index}. ${w.name}`}
                labelColor={w.selected ? '#00ff00' : '#ffffff'}
              >
                <ProgressBar
                  value={w.max_ammo > 0 ? w.ammo / w.max_ammo : 1}
                  ranges={{
                    good: [0.95, Infinity],
                    average: [0.15, 0.9],
                    bad: [-Infinity, 0.15],
                  }}
                >
                  {w.max_ammo > 0 ? `${w.ammo}/${w.max_ammo}` : 'READY'}
                </ProgressBar>
                <Box mt={1}>
                  {w.error ? `${w.error} (${w.cooldown_left}s)` : 'Ready'}
                  {w.selected ? ' - SELECTED' : ''}
                </Box>
                <Box>Priority: {w.priority}</Box>
                <Box>Weapon controllers: {w.controllers}</Box>
                <Button
                  mt={1}
                  selected={!!w.selected}
                  onClick={() => act('select_weapon', { index: w.index })}
                >
                  Select
                </Button>
                <br />
              </LabeledList.Item>
            ))}
          </LabeledList>
          <Box color="label" mt={1}>
            Keys 1-3 or Space select a weapon, left click fires it.
          </Box>
        </Section>
        <Section title="Log">
          {log.map((l, i) => (
            <Box key={i}>{l}</Box>
          ))}
        </Section>
        {!!data.is_admin && (
          <Section title="ADMIN">
            <Button onClick={() => act('spawn_raiders')}>Spawn raiders</Button>
            <Button onClick={() => act('spawn_cruiser')}>Spawn cruiser</Button>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
