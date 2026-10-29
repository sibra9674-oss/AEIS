// Port of NSV13 tgui/interfaces/TacticalConsole.js (Inferno/JS) to React/TS. Same ui_data / ui_act contract as nsv13/code/game/machinery/computer/tactical.dm.
import { useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NumberInput,
  ProgressBar,
  Section,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Weapon = {
  name: string;
  ammo: number;
  maxammo: number;
  controllers?: string;
  ammo_filter?: string;
  weapon_priority?: number;
  can_modify_priority?: BooleanLike;
  weapon_ref: string;
};

type Quadrants = {
  quadrant_fs_armour_current: number;
  quadrant_fs_armour_max: number;
  quadrant_as_armour_current: number;
  quadrant_as_armour_max: number;
  quadrant_ap_armour_current: number;
  quadrant_ap_armour_max: number;
  quadrant_fp_armour_current: number;
  quadrant_fp_armour_max: number;
};

type Painted = Quadrants & {
  name: string;
  integrity: number;
  max_integrity: number;
  faction: string;
};

export type TacticalData = Quadrants & {
  integrity: number;
  max_integrity: number;
  has_quadrant: BooleanLike;
  armour_integrity?: number;
  max_armour_integrity?: number;
  weapons: Weapon[];
  target_name: string;
  no_gun_cam: BooleanLike;
  additional_weapon_info: BooleanLike;
  modifying_weapon_priorities: BooleanLike;
  painted_targets: Painted[];
};

const HULL = { good: [0.95, Infinity], average: [0.15, 0.9], bad: [-Infinity, 0.15] } as const;
const QUAD = { good: [0.66, Infinity], average: [0.33, 0.66], bad: [-Infinity, 0.33] } as const;

const ratio = (cur: number, max: number) => (max ? cur / max : 0);

export const TacticalContent = () => {
  const { act, data } = useBackend<TacticalData>();
  const [current, setCurrent] = useState<string | null>(null);
  const [hidden, setHidden] = useState(true);

  return (
    <Section>
      <Section title="Ship status">
        <Section title="Hull integrity:">
          <ProgressBar value={ratio(data.integrity, data.max_integrity)} ranges={HULL} />
        </Section>
        <Section title="Armour:">
          {data.has_quadrant ? (
            <LabeledList>
              <LabeledList.Item label="Forward Port" labelColor="#ffffff">
                <ProgressBar value={ratio(data.quadrant_fp_armour_current, data.quadrant_fp_armour_max)} ranges={QUAD} />
              </LabeledList.Item>
              <LabeledList.Item label="Forward Starboard" labelColor="#ffffff">
                <ProgressBar value={ratio(data.quadrant_fs_armour_current, data.quadrant_fs_armour_max)} ranges={QUAD} />
              </LabeledList.Item>
              <LabeledList.Item label="Aft Port" labelColor="#ffffff">
                <ProgressBar value={ratio(data.quadrant_ap_armour_current, data.quadrant_ap_armour_max)} ranges={QUAD} />
              </LabeledList.Item>
              <LabeledList.Item label="Aft Starboard" labelColor="#ffffff">
                <ProgressBar value={ratio(data.quadrant_as_armour_current, data.quadrant_as_armour_max)} ranges={QUAD} />
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <LabeledList>
              <LabeledList.Item label="Integrity" labelColor="#ffffff">
                <ProgressBar
                  value={ratio(data.armour_integrity || 0, data.max_armour_integrity || 100)}
                  ranges={HULL}
                />
              </LabeledList.Item>
            </LabeledList>
          )}
        </Section>
      </Section>
      <Section
        title="Armaments:"
        buttons={
          <>
            <Button
              icon="cog"
              color={data.additional_weapon_info ? 'good' : 'default'}
              onClick={() => act('toggle_additional_weapon_info')}
            >
              Expanded Info
            </Button>
            <Button
              icon="wrench"
              color={data.modifying_weapon_priorities ? 'blue' : 'grey'}
              disabled={!data.additional_weapon_info}
              onClick={() => act('toggle_weapon_priority_modification')}
            />
          </>
        }
      >
        <LabeledList>
          {(data.weapons || []).map((value) =>
            value.maxammo ? (
              <LabeledList.Item key={value.weapon_ref} label={value.name} labelColor="#ffffff">
                <ProgressBar value={ratio(value.ammo, value.maxammo)} ranges={HULL} />
                {!!data.additional_weapon_info &&
                  (data.modifying_weapon_priorities && value.can_modify_priority ? (
                    <Box>
                      <br />
                      {'Priority: '}
                      <NumberInput
                        value={value.weapon_priority || 0}
                        width="47px"
                        minValue={1}
                        maxValue={900}
                        step={1}
                        onChange={(newPriority) =>
                          act('change_weapon_priority', {
                            target_weapon: value.weapon_ref,
                            new_priority: newPriority,
                          })
                        }
                      />
                    </Box>
                  ) : (
                    <Box>
                      <br />
                      {`Priority: ${value.weapon_priority}`}
                    </Box>
                  ))}
                {!!value.controllers && (
                  <Box>
                    <br />
                    {`Weapon controllers: ${value.controllers}`}
                  </Box>
                )}
                {!!value.ammo_filter && (
                  <Box>
                    <br />
                    {`Filtered ammo: ${value.ammo_filter}`}
                  </Box>
                )}
                <br />
              </LabeledList.Item>
            ) : null,
          )}
        </LabeledList>
      </Section>
      <Section title="Tracking:">
        {!data.no_gun_cam && (
          <Button fluid icon="bullseye" onClick={() => act('toggle_gun_camera')}>
            Toggle Gun Camera
          </Button>
        )}
        {(data.painted_targets || []).map((value) =>
          value.name ? (
            <Section key={value.name}>
              <Button
                fluid
                onClick={() => {
                  setCurrent(value.name);
                  setHidden(!hidden);
                }}
              >
                {value.name}
              </Button>
              {current === value.name && !hidden && (
                <Section title="Armour">
                  <LabeledList>
                    <LabeledList.Item label="Forward Starboard">
                      <ProgressBar value={ratio(value.quadrant_fs_armour_current, value.quadrant_fs_armour_max)} ranges={HULL} />
                    </LabeledList.Item>
                    <LabeledList.Item label="Forward Port">
                      <ProgressBar value={ratio(value.quadrant_fp_armour_current, value.quadrant_fp_armour_max)} ranges={HULL} />
                    </LabeledList.Item>
                    <LabeledList.Item label="Aft Starboard">
                      <ProgressBar value={ratio(value.quadrant_as_armour_current, value.quadrant_as_armour_max)} ranges={HULL} />
                    </LabeledList.Item>
                    <LabeledList.Item label="Aft Port">
                      <ProgressBar value={ratio(value.quadrant_ap_armour_current, value.quadrant_ap_armour_max)} ranges={HULL} />
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              )}
              <Section>
                <LabeledList>
                  <LabeledList.Item label="Integrity">
                    <ProgressBar value={ratio(value.integrity, value.max_integrity)} ranges={HULL} />
                  </LabeledList.Item>
                </LabeledList>
              </Section>
              <Button fluid icon="bullseye" onClick={() => act('lock_ship', { target: value.name })}>
                {data.target_name === value.name ? `Stop Targeting ${value.name}` : `Target ${value.name}`}
              </Button>
              <Button fluid icon="bullseye" onClick={() => act('dump_lock', { target: value.name })}>
                {`Stop Tracking ${value.name}`}
              </Button>
            </Section>
          ) : null,
        )}
      </Section>
    </Section>
  );
};

export const TacticalConsole = () => (
  <Window theme="nanotrasen" width={560} height={600}>
    <Window.Content scrollable>
      <TacticalContent />
    </Window.Content>
  </Window>
);
