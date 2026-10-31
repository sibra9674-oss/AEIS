// Port of NSV13 tgui/interfaces/PlasmaGun.js (Inferno) to TGMC React/TS. Mechanical conversion, not compiled.
import { useBackend, useLocalState } from '../backend';
import { Button, Section, ProgressBar, Table } from 'tgui-core/components';
import { Window } from '../layouts';
import { toFixed } from 'tgui-core/math';


// Forgot to change the Plasma Load to Ammo but I did that now //
// I also removed the old bar //

export const PlasmaGun = (props: any) => {
  const { act, data } = useBackend<any>();
  return (
    <Window
      theme="dominion"
      width={560}
      height={600}>
      <Window.Content scrollable>
        <Section>
          <Table.Row>
            <Table.Cell collapsing>
              <Section title="Splines:">
                <ProgressBar
                  value={(100 - data.cooldown) * .01}
                  ranges={{
                    good: [0.5, Infinity],
                    average: [0.15, 0.5],
                    bad: [-Infinity, 0.15],
                  }}
                />
              </Section>
            </Table.Cell>
          </Table.Row>
        </Section>
        <Section>
          <Table.Row>
            <Table.Cell collapsing>
              <Section title="Plasma Capacitor Charge:">
                <ProgressBar
                  value={(data.plasma_moles/data.plasma_moles_max * 100)* 0.01}
                  ranges={{
                    good: [0.5, Infinity],
                    average: [0.15, 0.5],
                    bad: [-Infinity, 0.15],
                  }}
                />
              </Section>
            </Table.Cell>
            <Table.Cell collapsing>
              <Section title="Plasma Load:">
                <ProgressBar
                  value={(data.ammo / data.max_ammo * 100) * 0.01}
                  ranges={{
                    good: [0.5, Infinity],
                    average: [0.15, 0.5],
                    bad: [-Infinity, 0.15],
                  }}
                />
              </Section>
            </Table.Cell>
          </Table.Row>
          <Section title="Field Alignment">
            <ProgressBar
              value={data.alignment * 0.01}
              ranges={{
                good: [0.5, Infinity],
                average: [0.15, 0.5],
                bad: [-Infinity, 0.15],
              }}
            />
          </Section>
          <Section title="Field Integrity:">
            <ProgressBar
              value={data.field_integrity * 0.01}
              ranges={{
                good: [0.5, Infinity],
                average: [0.15, 0.5],
                bad: [-Infinity, 0.15],
              }}
            />
          </Section>
        </Section>
        <Section title="Deterrant System Controls:">
          <Button
            fluid
            icon={data.loaded ? "check-circle" : "square-o"}
            color={data.loaded ? "red" : ""}
            width="100"
            selected={data.loaded}
            content="Condense Phoron Mass"
            onClick={() => act('toggle_load')}
          />
          <Button
            fluid
            icon={data.chambered ? "check-circle" : "square-o"}
            color={data.chambered ? "red" : ""}
            width="100"
            selected={data.chambered}
            content="Commence Magnetic Charge"
            onClick={() => act('chamber')}
          />
          <Button
            fluid
            icon={data.safety ? "power-off" : "times"}
            color={data.safety ? "red" : ""}
            width="100"
            selected={data.safety}
            content="Release Constrictor Field"
            onClick={() => act('toggle_safety')}
          />
        </Section>
      </Window.Content>
    </Window>
  );
};
